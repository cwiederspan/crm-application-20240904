variable "base_name" {
  type        = string
  description = "A base for the naming scheme as part of prefix-base-suffix."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "home_ip" {
  type = string
  description = "The CIDR block for your home IP address. Likely ends with a /32"
}

variable "app_config" {
  type = map(list(object({
    app_service_plan_name = string
    resource_group_name   = string
    location              = string
    type                  = string
    sku                   = string
  })))
}

locals {
  app_configs = [
    {
      app_service_plan_name = "${var.base_name}-01-plan"
      resource_group_name   = azurerm_resource_group.rg.name
      location              = var.location
      type                  = "Windows"
      sku                   = "P1v3"
    },
    {
      app_service_name      = "${var.base_name}-02-plan"
      resource_group_name   = azurerm_resource_group.rg.name
      location              = var.location
      type                  = "Windows"
      sku                   = "P1v3"
    }
  ]
}

resource "azurerm_resource_group" "rg" {
  name     = var.base_name
  location = var.location

  # ignore changes to tags
  lifecycle {
    ignore_changes = [tags]
  }
}

module "name" {
  for_each = var.app_config

  source          = "./modules/appserviceplan"
  resource_group  = each.value.resource_group_name
  name            = each.value.app_service_name   # "${var.base_name}-plan"
  location        = each.value.location
  type            = each.value.type
  sku             = each.value.sku
}