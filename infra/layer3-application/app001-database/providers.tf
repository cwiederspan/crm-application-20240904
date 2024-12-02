terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      version = "~> 4.0"
    }
    azapi = {
      source = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features { }
}