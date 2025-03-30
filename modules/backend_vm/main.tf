
locals {
  vm_suffix  ="${var.backend_vm_name}${random_string.backedn_vm_name_prefix.result}"
}


resource "random_string" "backedn_vm_name_prefix" {
  length = 3  
  special = false
}


resource "azurerm_network_interface" "backend_vm_nic" {
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  resource_group_name = var.resource_group_name
  location            = var.region
  name                = "backend_vm_nic1-${local.vm_suffix}"
  
}



resource "azurerm_network_security_group" "backend_nsg" {
  name                = "backend_vm_nsg-${local.vm_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.region

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_security_rule" "backend_nsg_http" {
  name                        = "http-rule"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.backend_nsg.name
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  access                      = "Allow"
  direction                   = "Inbound"
  priority                    = 200
  source_address_prefix = "*"
  destination_address_prefix = "*"

  lifecycle {
    create_before_destroy = true
  }

}


resource "azurerm_network_interface_security_group_association" "backend_nsg_association" {
  network_interface_id      = azurerm_network_interface.backend_vm_nic.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id

  lifecycle {
    create_before_destroy = true
  }


}


resource "azurerm_virtual_machine" "backend_virtual_machine" {
  name                  = local.vm_suffix
  resource_group_name   = var.resource_group_name
  location              = var.region
  network_interface_ids = [azurerm_network_interface.backend_vm_nic.id]

  vm_size = var.backend_vm_size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1--${local.vm_suffix}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"

    admin_username = "azureuser"
    admin_password = "Azure@#$12345"
    # custom_data    = base64encode(file("${path.module}/new-script.sh"))
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [ boot_diagnostics ]
  }

}


