resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "${var.base_name}-wksp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}