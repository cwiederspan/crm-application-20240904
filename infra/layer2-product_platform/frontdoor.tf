resource "azurerm_cdn_frontdoor_profile" "afd" {
  name                = "${var.base_name}-afd"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"

  response_timeout_seconds = 60
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "${var.base_name}-main"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
}

resource "azurerm_cdn_frontdoor_origin_group" "default" {
  name                     = "default-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
  session_affinity_enabled = false

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 0

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Http"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  name                = replace("${var.base_name}-waf", "-", "")
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"
  mode                = "Detection"
  enabled             = true
}

output "afd_endpoint_id" {
  value = azurerm_cdn_frontdoor_endpoint.main.id
}

output "afd_default_origin_group_id" {
  value = azurerm_cdn_frontdoor_origin_group.default.id
}