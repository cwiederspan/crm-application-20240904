resource "azurerm_service_plan" "plan" {
  name                = "${var.base_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type = "Windows"
  sku_name = "P0v3"
}

resource "azurerm_windows_web_app" "app" {
  name                = "${var.base_name}-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id = azurerm_service_plan.plan.id

  https_only = true

  public_network_access_enabled                  = true
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  site_config {
    vnet_route_all_enabled = true
    use_32_bit_worker      = false
    http2_enabled          = true
    always_on              = true
    ftps_state             = "Disabled"

    application_stack {
      current_stack = "dotnet"
      dotnet_version = "v8.0"
    }

    ip_restriction {
      action = "Allow"
      ip_address = var.home_ip
      name = "home"
      priority = 100
    }

    ip_restriction_default_action = "Deny"

    scm_ip_restriction_default_action = "Allow"
  }

  // This is the wire-up to the outbound/egress subnet
  virtual_network_subnet_id = azurerm_subnet.appOutbound.id
}

resource "azurerm_private_endpoint" "app_private_endpoint" {
  name                = "${var.base_name}-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # This is the subnet where we put the Private Endpoint for incoming traffic
  subnet_id           = azurerm_subnet.appInbound.id

  private_service_connection {
    name                           = "${var.base_name}-pe-conn"
    private_connection_resource_id = azurerm_windows_web_app.app.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_a_record" "app_dns" {
  name                = azurerm_windows_web_app.app.name
  zone_name           = azurerm_private_dns_zone.appservice_dns_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 10
  records             = [azurerm_private_endpoint.app_private_endpoint.private_service_connection.0.private_ip_address]
}

resource "azurerm_private_dns_a_record" "scm_dns" {
  name                = "${azurerm_windows_web_app.app.name}.scm"
  zone_name           = azurerm_private_dns_zone.appservice_dns_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 10
  records             = [azurerm_private_endpoint.app_private_endpoint.private_service_connection.0.private_ip_address]
}




resource "azurerm_windows_web_app" "app-main" {
  name                = "${var.base_name}-main-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id = azurerm_service_plan.plan.id

  https_only = true

  public_network_access_enabled                  = true
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  site_config {
    vnet_route_all_enabled = true
    use_32_bit_worker      = false
    http2_enabled          = true
    always_on              = true
    ftps_state             = "Disabled"

    application_stack {
      current_stack = "dotnet"
      dotnet_version = "v8.0"
    }

    ip_restriction {
      action = "Allow"
      ip_address = var.home_ip
      name = "home"
      priority = 100
    }

    ip_restriction_default_action = "Deny"

    scm_ip_restriction_default_action = "Allow"
  }

  // This is the wire-up to the outbound/egress subnet
  virtual_network_subnet_id = azurerm_subnet.appOutbound.id
}

resource "azurerm_private_endpoint" "app_private_endpoint-main" {
  name                = "${var.base_name}-main-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # This is the subnet where we put the Private Endpoint for incoming traffic
  subnet_id           = azurerm_subnet.appInbound.id

  private_service_connection {
    name                           = "${var.base_name}-main-pe-conn"
    private_connection_resource_id = azurerm_windows_web_app.app-main.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_a_record" "app_dns-main" {
  name                = azurerm_windows_web_app.app-main.name
  zone_name           = azurerm_private_dns_zone.appservice_dns_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 10
  records             = [azurerm_private_endpoint.app_private_endpoint-main.private_service_connection.0.private_ip_address]
}

resource "azurerm_private_dns_a_record" "scm_dns-main" {
  name                = "${azurerm_windows_web_app.app-main.name}.scm"
  zone_name           = azurerm_private_dns_zone.appservice_dns_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 10
  records             = [azurerm_private_endpoint.app_private_endpoint-main.private_service_connection.0.private_ip_address]
}