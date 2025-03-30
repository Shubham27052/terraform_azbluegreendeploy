resource "azurerm_lb" "load_balancer" {
    name = var.lb_name
    resource_group_name = var.resource_group_name
    location = var.region

    sku = "Standard"
    sku_tier = "Regional"

    frontend_ip_configuration {
      name = "frontend-pip"
      public_ip_address_id = var.lb_pip_id
    }
}


resource "azurerm_lb_backend_address_pool" "load_balancer_backend_pool" {
    name = "backend-pool-1"
    loadbalancer_id = azurerm_lb.load_balancer.id  
}


resource "azurerm_lb_backend_address_pool_address" "load_balancer_backend_pool_address" {
  name = "address-1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.load_balancer_backend_pool.id
  ip_address = var.backend_vm_ip
  virtual_network_id = var.virtual_network_id


}


resource "azurerm_lb_probe" "load_balancer_http_probe" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "ssh-running-probe"
  port            = 80
}


resource "azurerm_lb_rule" "azurerm_lb_http_rule" {
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "Http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-pip"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.load_balancer_backend_pool.id]
  probe_id = azurerm_lb_probe.load_balancer_http_probe.id
}







