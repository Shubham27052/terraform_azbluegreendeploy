output "backend_vm_ip" {
  value = azurerm_network_interface.backend_vm_nic.private_ip_address
}

output "backend_vm_name" {
  value = azurerm_virtual_machine.backend_virtual_machine.name
  
}

output "backend_vm_id" {
  value = azurerm_virtual_machine.backend_virtual_machine.id
  
}