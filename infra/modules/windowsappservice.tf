variable "app_service_name" {
    type        = string
    description = "The name of the App Service to create."
}

variable "resource_group_name" {
    type        = string
    description = "The name of the resource group where the App Service Plan will be created."
}

variable "location" {
    type        = string
    description = "The Azure region where the resources will be created."
}

variable "app_service_plan_id" {
    type        = string
    description = "The ID of the App Service Plan where the App Service will be created."
}

variable "vnet_subnet_id" {
    type        = string
    description = "The ID of the subnet that the App Service will use to access database and other internal resources."
}

variable "application_stack" {
    type        = string
    description = "The application stack settings for the App Service."
    default     = "dotnet"
}

# variable "application_stack_version" {
#     type        = string
#     description = "The application stack version value for the App Service."
#     default     = "dotnet"
# }

variable "https_only" {
    type        = bool
    description = "If true, the App Service will only accept HTTPS traffic."
    default     = true
}

variable "use_32_bit_worker" {
    type        = bool
    description = "If true, the App Service will use a 32-bit worker process."
    default     = true
}

resource "azurerm_windows_web_app" "app" {
  name                = var.app_service_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.app_service_plan_id

  https_only = var.https_only

#   public_network_access_enabled                  = true
#   ftp_publish_basic_authentication_enabled       = false
#   webdeploy_publish_basic_authentication_enabled = false

  site_config {
    vnet_route_all_enabled = true
    use_32_bit_worker      = var.use_32_bit_worker
    # http2_enabled          = true
    always_on              = true
    # ftps_state             = "Disabled"

    application_stack {
      current_stack = var.application_stack
    #   dotnet_version = "v8.0"
    }

    virtual_application {
      virtual_path = "/"
      preload = 
      physical_path = "/site/wwwroot"
    }

    # ip_restriction {
    #   action = "Allow"
    #   ip_address = var.home_ip
    #   name = "home"
    #   priority = 100
    # }

    ip_restriction_default_action = "Deny"

    scm_ip_restriction_default_action = "Allow"
  }

  // This is the wire-up to the outbound/egress subnet
  virtual_network_subnet_id = var.vnet_subnet_id
}