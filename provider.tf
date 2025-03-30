terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "f5a72aa1-60c1-4225-90ba-4e5273d6af91"
  tenant_id       = "980a9497-3393-4e89-9671-4f0f938006fe"
}


