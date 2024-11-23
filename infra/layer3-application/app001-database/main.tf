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

# variable "user_managed_identity" {
#   type        = string
#   description = "The principal or application ID of the Azure user managed identity to assign to the resources."
# }

# variable "key_vault_uri" {
#   type        = string
#   description = "The URI to the key vault where app service secretes are stored."
# }

resource "azurerm_resource_group" "rg" {
  name     = var.base_name
  location = var.location
  
  # ignore changes to tags
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.base_name}-sqlsvr-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.database_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}