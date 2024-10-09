terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      version = "~> 4.0"
    }
    time = {
      source = "hashicorp/time"
      version = "0.12.1"
    }
  }
}

provider "azurerm" {

  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "time" {
  # Configuration options
}