variable "resource_group_name" {
    type = string  
}

variable "region" {
    type = string
}

variable "lb_name" {
    type = string 
}

variable "lb_pip_id" {
    type = string
}

variable "backend_vm_ip" {
  type = string
}

variable "virtual_network_id" {
  type = string
}
