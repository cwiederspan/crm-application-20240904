variable "base_name" {
  type        = string
  description = "A base for the naming scheme as part of prefix-base-suffix."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
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

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.workspace.id
}

output "user_managed_identity_id" {
  value = azurerm_user_assigned_identity.user_identity.id
}