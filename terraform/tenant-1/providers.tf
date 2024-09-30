terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
    backend "azurerm" {
      resource_group_name  = "rg-tfstate"
      container_name       = "tfstate"
      key                  = "tenant-1/terraform.tfstate"
      use_azuread_auth     = true
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
}