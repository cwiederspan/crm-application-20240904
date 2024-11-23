variable "base_name" {
  type        = string
  description = "A base for the naming scheme as part of prefix-base-suffix."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "database_subnet_id" {
  type        = string
  description = "The id of the subnet that the database servers will use to communicate with other services."
}

resource "azurerm_resource_group" "rg" {
  name     = var.base_name
  location = var.location
  
  # ignore changes to tags
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_user_assigned_identity" "user_identity" {
  name                = "${var.base_name}-id"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

output "user_managed_identity_id" {
  value = azurerm_user_assigned_identity.user_identity.id
}