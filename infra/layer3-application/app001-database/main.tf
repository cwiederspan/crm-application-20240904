variable "base_name" {
  type        = string
  description = "A base for the naming scheme as part of prefix-base-suffix."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "database_subnet_id" {
  type        = string
  description = "The id of the subnet that the database servers will use to communicate with other services."
}

# variable "user_managed_identity" {
#   type        = string
#   description = "The principal or application ID of the Azure user managed identity to assign to the resources."
# }

# variable "key_vault_uri" {
#   type        = string
#   description = "The URI to the key vault where app service secretes are stored."
# }

resource "azurerm_resource_group" "rg" {
  name     = var.base_name
  location = var.location
  
  # ignore changes to tags
  lifecycle {
    ignore_changes = [tags]
  }
}

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


/*
resource "azurerm_virtual_machine" "vm" {
  name                  = "sql-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_M128bds_3_v3"

  storage_os_disk {
    name              = "sql-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2019-WS2019"
    sku       = "Enterprise"
    version   = "latest"
  }

  os_profile {
    computer_name  = "sqlvm"
    admin_username = "adminuser"
    admin_password = "P@ssword123!"
  }

  os_profile_windows_config {}
}

# Data Disks
resource "azurerm_managed_disk" "data_disks" {
  count                = 8
  name                 = "data-disk-${count.index + 1}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "PremiumV2"
  disk_size_gb         = 1792
}

# Log Disks
resource "azurerm_managed_disk" "log_disks" {
  count                = 4
  name                 = "log-disk-${count.index + 1}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "PremiumV2"
  disk_size_gb         = 1024
}

# Attach Data Disks
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachments" {
  count              = 8
  virtual_machine_id = azurerm_virtual_machine.vm.id
  managed_disk_id    = azurerm_managed_disk.data_disks[count.index].id
  lun                = count.index
  caching            = "ReadOnly"
}

# Attach Log Disks
resource "azurerm_virtual_machine_data_disk_attachment" "log_disk_attachments" {
  count              = 4
  virtual_machine_id = azurerm_virtual_machine.vm.id
  managed_disk_id    = azurerm_managed_disk.log_disks[count.index].id
  lun                = count.index + 8
  caching            = "None"
}




# Data Disks
resource "azurerm_managed_disk" "data_disks" {
  count                = 16
  name                 = "data-disk-${count.index + 1}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "PremiumV2"
  disk_size_gb         = 896
}

# Log Disks
resource "azurerm_managed_disk" "log_disks" {
  count                = 16
  name                 = "log-disk-${count.index + 1}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "PremiumV2"
  disk_size_gb         = 256
}

# Attach Data Disks
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachments" {
  count              = 16
  virtual_machine_id = azurerm_virtual_machine.vm.id
  managed_disk_id    = azurerm_managed_disk.data_disks[count.index].id
  lun                = count.index
  caching            = "ReadOnly"
}

# Attach Log Disks
resource "azurerm_virtual_machine_data_disk_attachment" "log_disk_attachments" {
  count              = 16
  virtual_machine_id = azurerm_virtual_machine.vm.id
  managed_disk_id    = azurerm_managed_disk.log_disks[count.index].id
  lun                = count.index + 16
  caching            = "None"
}

*/