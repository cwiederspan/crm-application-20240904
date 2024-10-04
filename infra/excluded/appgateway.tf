locals {
  app_gateway_name               = "${var.base_name}-appgw"
  gateway_ip_config_name         = "${local.app_gateway_name}-gwip"
  backend_address_pool_name      = "${local.app_gateway_name}-beap"
  frontend_port_name             = "${local.app_gateway_name}-feport"
  frontend_ip_configuration_name = "${local.app_gateway_name}-feip"
  http_setting_name              = "${local.app_gateway_name}-be-htst"
  listener_name                  = "${local.app_gateway_name}-httplstn"
  request_routing_rule_name      = "${local.app_gateway_name}-rqrt"
  probe_name                     = "${local.app_gateway_name}-probe"
  url_path_name                  = "${local.app_gateway_name}-up"
  redirect_configuration_name    = "${local.app_gateway_name}-rc"
}

resource "azurerm_application_gateway" "gateway" {
  name                = local.app_gateway_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  # identity {
  #   type = "UserAssigned"
  #   identity_ids = [
  #     azurerm_user_assigned_identity.appgwmsi.id
  #   ]
  # }

  gateway_ip_configuration {
    name      = local.gateway_ip_config_name
    subnet_id = azurerm_subnet.gateway.id
  }

  # ssl_certificate {
  #   name                = "${var.base_name}-ssl"
  #   key_vault_secret_id = azurerm_key_vault_certificate.cert.secret_id
  # }

  # trusted_root_certificate {
  #   name = "${var.base_name}-trc"
  #   data = azurerm_key_vault_certificate.cert.certificate_data_base64
  # }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.ip.id
  }

  frontend_port {
    name = "${local.frontend_port_name}-http"
    port = 80
  }

  frontend_port {
    name = "${local.frontend_port_name}-https"
    port = 443
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}-sso"
    # ip_addresses = [
    #   azurerm_api_management.apim.private_ip_addresses[0]
    # ]
    fqdns = [
      azurerm_windows_web_app.app.default_hostname
    ]
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}-main"
    # ip_addresses = [
    #   azurerm_api_management.apim.private_ip_addresses[0]
    # ]
    fqdns = [
      azurerm_windows_web_app.app-main.default_hostname
    ]
  }

  # http_listener {
  #   name                           = "${local.listener_name}-sso"
  #   frontend_ip_configuration_name = local.frontend_ip_configuration_name
  #   frontend_port_name             = "${local.frontend_port_name}-https"
  #   protocol                       = "Https"
  #   //ssl_certificate_name           = "${var.base_name}-ssl"
  #   //host_names                     = [local.apim_management_dns_name]
  #   //require_sni                    = true
  # }

  http_listener {
    name                           = "${local.listener_name}-sso"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "${local.frontend_port_name}-http"
    protocol                       = "Http"
  }
  

  backend_http_settings {
    name                  = "${local.http_setting_name}-sso"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 180

    pick_host_name_from_backend_address = true

    # trusted_root_certificate_names = ["${var.base_name}-trc"]
    # probe_name = "${local.probe_name}-management"
    # host_name  = local.apim_management_dns_name
  }

  # probe {
  #   name                = "${local.probe_name}-management"
  #   protocol            = "Https"
  #   path                = "/ServiceStatus"
  #   interval            = 30
  #   timeout             = 120
  #   unhealthy_threshold = 8
  #   host                = local.apim_management_dns_name
  # }

  # request_routing_rule {
  #   name      = "${local.request_routing_rule_name}-sso"
  #   rule_type = "Basic"
  #   priority  = 10

  #   backend_address_pool_name  = "${local.backend_address_pool_name}-sso"
  #   http_listener_name         = "${local.listener_name}-sso"
  #   backend_http_settings_name = "${local.http_setting_name}-sso"
  # }

  request_routing_rule {
    name      = "${local.request_routing_rule_name}-sso"
    rule_type = "PathBasedRouting"
    priority  = 9

    # backend_address_pool_name  = "${local.backend_address_pool_name}-sso"
    # backend_http_settings_name = "${local.http_setting_name}-sso"
    http_listener_name = "${local.listener_name}-sso"
    url_path_map_name  = local.url_path_name
  }

  url_path_map {
    name = local.url_path_name
    default_backend_address_pool_name   = "${local.backend_address_pool_name}-main"
    default_backend_http_settings_name  = "${local.http_setting_name}-sso"

    # default_redirect_configuration_name = local.redirect_configuration_name

    path_rule {
      name       = "test"
      paths      = ["/test/*"]

      backend_address_pool_name  = "${local.backend_address_pool_name}-sso"
      backend_http_settings_name = "${local.http_setting_name}-sso"
    }
  }

  # redirect_configuration {
  #   name = local.redirect_configuration_name
  #   redirect_type = "Temporary"
  #   target_url = "https://www.microsoft.com"
  # }
}
