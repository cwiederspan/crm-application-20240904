terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features { }
}