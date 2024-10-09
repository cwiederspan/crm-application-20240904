data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = substr("kv-${var.base_name}", 0, 24)
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true
}

# Make the current Terraform user (whoever is runnign this script) a Key Vault Administrator so they can create secrets
resource "azurerm_role_assignment" "kv_admin_role" {
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.kv.id
  principal_id         = data.azurerm_client_config.current.object_id
}

# Add an assignment so the User Assigned Identity can read secrets
resource "azurerm_role_assignment" "kv_user_role" {
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.kv.id
  principal_id         = azurerm_user_assigned_identity.user_identity.principal_id
}

# Add a delay to allow the Key Vault permissions to propogate before adding secrets
resource "time_sleep" "delay" {
  depends_on = [ azurerm_role_assignment.kv_admin_role ]
  create_duration = "30s"
}

# Add a dummy secret for testing purposes
resource "azurerm_key_vault_secret" "secret" {
  key_vault_id = azurerm_key_vault.kv.id
  name = "TestSecret"
  value = "Top Secret Value!"

  depends_on = [ time_sleep.delay ]
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}