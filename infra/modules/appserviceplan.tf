variable "resource_group" {
    type        = string
    description = "The name of the resource group where the App Service Plan will be created."
}

variable "name" {
    type        = string
    description = "The name of the App Service Plan."
}

variable "location" {
    type        = string
    description = "The Azure region where the resources will be created."
}

variable "type" {
    type        = string
    description = "The type of the App Service Plan. Valid values are Windows or Linux."
    default     = "Windows"
}

variable "sku" {
    type        = string
    description = "The SKU of the App Service Plan."
    default     = "P1v3"
}

resource "azurerm_service_plan" "plan" {
    name                = var.name
    location            = var.location
    resource_group_name = var.resource_group
    os_type             = var.type
    sku_name            = var.sku
}

output "app_service_plan_id" {
    value = azurerm_service_plan.plan.id
}