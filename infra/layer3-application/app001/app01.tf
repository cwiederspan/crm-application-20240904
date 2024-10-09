# resource "azurerm_windows_web_app" "app01" {
#   name                = "${var.base_name}-01-app"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   service_plan_id     = azurerm_service_plan.plan.id

#   https_only = true

#   ftp_publish_basic_authentication_enabled       = false
#   webdeploy_publish_basic_authentication_enabled = false

#   // This is the wire-up to the outbound/egress subnet
#   virtual_network_subnet_id = var.outbound_subnet_id

#   // This is the user that will be use to access the key vault secrets
#   key_vault_reference_identity_id = var.user_managed_identity

#   // Setup the app service with a user assigned identity
#   identity {
#     type = "UserAssigned"
#     identity_ids = [var.user_managed_identity]
#   }

#   site_config {
#     vnet_route_all_enabled = true
#     use_32_bit_worker      = false
#     http2_enabled          = true
#     always_on              = true
#     ftps_state             = "Disabled"

#     application_stack {
#       current_stack = "dotnet"
#       dotnet_version = "v8.0"
#     }

#     virtual_application {
#       virtual_path = "/"
#       physical_path = "site\\wwwroot"
#       preload = true
#     }

#     virtual_application {
#       virtual_path = "/app01"
#       physical_path = "site\\wwwroot"
#       preload = true
#     }
#   }

#   app_settings = {
#     "MY_SETTING" = "Something Special!"
#     "MY_SECRET"  = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/TestSecret)"
#   }
# }

module "app01" {
  source = "../../modules/app_service"

  app_settings = {
    "MY_SETTING" = "Something Special!"
    "MY_SECRET"  = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/TestSecret)"
  }

  outbound_subnet_id = var.outbound_subnet_id
  user_managed_identity = var.user_managed_identity
  web_app_name = "${var.base_name}-01-app"
  key_vault_uri = var.key_vault_uri
  service_plan_id = azurerm_service_plan.plan.id
  
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  virtual_applications = [ 
    {
      virtual_path = "/app01"
      physical_path = "site\\wwwroot"
    },
    {
      virtual_path = "/"
      physical_path = "site\\wwwroot"
    }
   ]
}

module "app02" {
  source = "../../modules/app_service"

  app_settings = {
    "MY_SETTING" = "Something Special!"
    "MY_SECRET"  = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/TestSecret)"
  }

  outbound_subnet_id = var.outbound_subnet_id
  user_managed_identity = var.user_managed_identity
  web_app_name = "${var.base_name}-02-app"
  key_vault_uri = var.key_vault_uri
  service_plan_id = azurerm_service_plan.plan.id
  
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  virtual_applications = [ 
    {
      virtual_path = "/app02"
      physical_path = "site\\wwwroot"
    },
    {
      virtual_path = "/app02/test"
      physical_path = "site\\wwwroot"
    },
    {
      virtual_path = "/"
      physical_path = "site\\wwwroot"
    }
   ]
}
