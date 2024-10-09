resource "azurerm_cdn_frontdoor_origin" "origin01_01" {
  name                           = "origin-app01-01"
  cdn_frontdoor_origin_group_id  = var.afd_default_origin_group_id
  enabled                        = true
  certificate_name_check_enabled = true

  host_name          = module.app01.default_hostname
  origin_host_header = module.app01.default_hostname
  http_port          = 80
  https_port         = 443
  priority           = 1
  weight             = 1000
}

resource "azurerm_cdn_frontdoor_route" "route01_01" {
  name                          = "route-app01-01"
  cdn_frontdoor_endpoint_id     = var.afd_endpoint_id
  cdn_frontdoor_origin_group_id = var.afd_default_origin_group_id
  cdn_frontdoor_origin_ids      = [] //azurerm_cdn_frontdoor_origin.app01_01.id]
  cdn_frontdoor_rule_set_ids    = [] #azurerm_cdn_frontdoor_rule_set.example.id]
  
  enabled                = true
  https_redirect_enabled = true
  forwarding_protocol    = "MatchRequest"
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  
  # cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.contoso.id, azurerm_cdn_frontdoor_custom_domain.fabrikam.id]
  link_to_default_domain          = true

  /*
  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                 = ["account", "settings"]
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  }*/

  depends_on = [
    azurerm_cdn_frontdoor_origin.origin01_01
  ]
}