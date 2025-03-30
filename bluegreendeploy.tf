# Variables
variable "resource_tags" {
  type = map(string)
  default = {
    "Owner"          = "Shubham Agarwal"
    "Deployment type" = "Blue Green"
    "Environment"    = "Dev"
  }
}


variable "subnets" {
  type = list(object({
    name             = string
    address_prefixes = list(string)
  }))

  default = [{
    "name"             = "subnet-1",
    "address_prefixes" = ["10.0.1.0/24"]
    },
    {
      "name"             = "subnet-2",
      "address_prefixes" = ["10.0.2.0/24"]
    },
    {
      "name"             = "subnet-3",
      "address_prefixes" = ["10.0.3.0/24"]
    },
    {
      "name"             = "subnet-4",
      "address_prefixes" = ["10.0.4.0/24"]
  }]
}


variable "backend_vm_name" {
  type    = string
  default = "Blue"

}


locals {

  execution_script_file_url = var.backend_vm_name == "Blue" ? "https://bgstorageaccount1234.blob.core.windows.net/deployment-scripts/bluevm_deploy_application.sh" : "https://bgstorageaccount1234.blob.core.windows.net/deployment-scripts/greenvm_deploy_application.sh"

  file_to_execute = var.backend_vm_name == "Blue" ? "bluevm_deploy_application.sh" : "greenvm_deploy_application.sh"

}



# Resources
resource "azurerm_resource_group" "bg_resource_group" {
  name     = "Blue-Green-Deployment"
  location = "Central India"
  tags     = var.resource_tags
}


resource "azurerm_virtual_network" "bg_vnet" {
  name                = "Blue-Green-Vnet"
  resource_group_name = azurerm_resource_group.bg_resource_group.name
  location            = azurerm_resource_group.bg_resource_group.location
  address_space       = ["10.0.0.0/16"]
}


resource "azurerm_subnet" "bg_subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  resource_group_name  = azurerm_resource_group.bg_resource_group.name
  virtual_network_name = azurerm_virtual_network.bg_vnet.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
}


resource "azurerm_public_ip" "bg_lb_pip" {
  name                = "bg_lb_pip"
  location            = azurerm_resource_group.bg_resource_group.location
  resource_group_name = azurerm_resource_group.bg_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


module "bg_lb" {
  source = "./modules/azure_loadbalancer"

  resource_group_name = azurerm_resource_group.bg_resource_group.name
  region              = azurerm_resource_group.bg_resource_group.location
  lb_name             = "bg_load_balancer"
  lb_pip_id           = azurerm_public_ip.bg_lb_pip.id
  backend_vm_ip       = module.bg_vm.backend_vm_ip
  virtual_network_id  = azurerm_virtual_network.bg_vnet.id

  depends_on = [
    azurerm_virtual_machine_extension.backend_vm_deployapp_extension
  ]

}


module "bg_vm" {
  source = "./modules/backend_vm"

  resource_group_name = azurerm_resource_group.bg_resource_group.name
  region              = azurerm_resource_group.bg_resource_group.location
  subnet_id           = azurerm_subnet.bg_subnets["subnet-1"].id
  backend_vm_name     = var.backend_vm_name
  backend_vm_size     = "Standard_B1s"

}


resource "azurerm_storage_account" "bg_storage_account" {
  name                     = "bgstorageaccount1234"
  location                 = azurerm_resource_group.bg_resource_group.location
  resource_group_name      = azurerm_resource_group.bg_resource_group.name
  account_tier             = "Standard"
  account_replication_type = "LRS"



}


resource "azurerm_storage_container" "deployment_scripts" {
  name                 = "deployment-scripts"
  storage_account_name = azurerm_storage_account.bg_storage_account.name

}


resource "azurerm_storage_blob" "backend_bluevm_deploy_application" {
  name                   = "bluevm_deploy_application.sh"
  storage_account_name   = azurerm_storage_account.bg_storage_account.name
  storage_container_name = azurerm_storage_container.deployment_scripts.name
  type                   = "Block"
  source                 = "./scripts/bluevm_deploy_application.sh"

}


resource "azurerm_storage_blob" "backend_greenvm_deploy_application" {
  name                   = "greenvm_deploy_application.sh"
  storage_account_name   = azurerm_storage_account.bg_storage_account.name
  storage_container_name = azurerm_storage_container.deployment_scripts.name
  type                   = "Block"
  source                 = "./scripts/greenvm_deploy_application.sh"

}


resource "azurerm_virtual_machine_extension" "backend_vm_deployapp_extension" {
  name                 = module.bg_vm.backend_vm_name
  virtual_machine_id   = module.bg_vm.backend_vm_id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = jsonencode({
    "fileUris" : [local.execution_script_file_url],
    "commandToExecute" : "sudo bash ${local.file_to_execute}"
  })

  # For sensitive information
  protected_settings = jsonencode({
    "storageAccountName" : "${azurerm_storage_account.bg_storage_account.name}",
    "storageAccountKey" : "${azurerm_storage_account.bg_storage_account.primary_access_key}"
  })

  depends_on = [
    module.bg_vm,
  ]

  lifecycle {
    create_before_destroy = true
  }

}




output "application_url" {
  value       = "http://${azurerm_public_ip.bg_lb_pip.ip_address}"
  description = "Access the application at: "

}