variable "base_name" {
  type        = string
  description = "A base for the naming scheme as part of prefix-base-suffix."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "user_managed_identity" {
  type        = string
  description = "The principal or application ID of the Azure user managed identity to assign to the resources."
}

variable "outbound_subnet_id" {
  type        = string
  description = "The id of the subnet that the app services will use to communicate with other services."
}

variable "key_vault_uri" {
  type        = string
  description = "The URI to the key vault where app service secretes are stored."
}

variable "afd_endpoint_id" { 
  type        = string
  description = "The id of the Azure Front Door endpoint to use for traffic routing."
}

variable "afd_default_origin_group_id" {
  type        = string
  description = "The id of the Azure Front Door's default origin group that is available."
}

resource "azurerm_resource_group" "rg" {
  name     = var.base_name
  location = var.location
  
  # ignore changes to tags
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.base_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type = "Windows"
  sku_name = "P0v3"
}