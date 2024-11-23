

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