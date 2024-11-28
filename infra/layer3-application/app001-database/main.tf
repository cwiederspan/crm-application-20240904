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

variable "log_analytics_workspace_id" {
  type        = string
  description = "The id of the Azure Monitor's Log Analytics workspace that will be used for logging and metrics."
}

variable "availability_zone_id" {
  type = string
  description = "The availability zone to deploy into (required by Premium SSD v2 disks)."
}

variable "vm_admin_username" {
  type        = string
  description = "The username for the database virtual machine."
}

variable "vm_admin_password" {
  type        = string
  description = "The password for the database virtual machine."
}

variable "sql_admin_username" {
  type        = string
  description = "The username for the SQL admin user."
}

variable "sql_admin_password" {
  type        = string
  description = "The password for the SQL admin user."
}

variable "data_disk_count" {
  type        = number
  description = "The number of data disks to attach to the database virtual machine."
}

variable "data_disk_size_gb" {
  type        = number
  description = "The size of the data disks to attach to the database virtual machine."
}

variable "data_disk_iops" {
  type        = number
  description = "The number of IOPS to assign to the data disks."
}

variable "data_disk_throughput" {
  type        = number
  description = "The throughput to assign to the data disks."
}

variable "logs_disk_count" {
  type        = number
  description = "The number of log disks to attach to the database virtual machine."
}

variable "logs_disk_size_gb" {
  type        = number
  description = "The size of the log disks to attach to the database virtual machine."
}

variable "logs_disk_iops" {
  type        = number
  description = "The number of IOPS to assign to the log disks."
}

variable "logs_disk_throughput" {
  type        = number
  description = "The throughput to assign to the log disks."
}

# variable "user_managed_identity" {
#   type        = string
#   description = "The principal or application ID of the Azure user managed identity to assign to the resources."
# }

# variable "key_vault_uri" {
#   type        = string
#   description = "The URI to the key vault where app service secretes are stored."
# }

data "azurerm_client_config" "current" {}

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

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "${var.base_name}-sqlvm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  admin_username        = var.vm_admin_username
  admin_password        = var.vm_admin_password
  size                  = "Standard_E4bds_v5"
  computer_name         = "vm-sql001-001"
  zone                  = var.availability_zone_id
  disk_controller_type  = "NVMe"
  license_type          = "Windows_Server"
  secure_boot_enabled   = true
  
  source_image_reference {
    publisher = "microsoftsqlserver"
    offer     = "sql2022-ws2022"
    sku       = "enterprise-gen2"
    version   = "latest"
  }

  os_disk {
    caching                   = "ReadWrite"
    storage_account_type      = "Premium_LRS"
    # write_accelerator_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "monitor_agent" {
  name                 = "AzureMonitorWindowsAgent"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.0"

  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
}

resource "azurerm_managed_disk" "data_disks" {
  count                = var.data_disk_count
  name                 = "${var.base_name}-sqlvm-data-disk-${count.index + 1}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name

  storage_account_type = "PremiumV2_LRS"
  create_option        = "Empty"
  zone                 = var.availability_zone_id

  disk_size_gb         = var.data_disk_size_gb
  disk_mbps_read_write = var.data_disk_throughput
  disk_iops_read_write = var.data_disk_iops
  os_type              = "Windows"
}

# Attach Logs Disks
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachments" {
  count              = var.data_disk_count
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  managed_disk_id    = azurerm_managed_disk.data_disks[count.index].id
  lun                = count.index
  caching            = "None"   # Premium SSD v2 do not support host caching
  # caching            = "ReadOnly"  # ReadOnly for data, per this page - https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/performance-guidelines-best-practices-storage?view=azuresql
}

resource "azurerm_managed_disk" "logs_disks" {
  count                = var.logs_disk_count
  name                 = "${var.base_name}-sqlvm-logs-disk-${count.index + 1}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name

  storage_account_type = "PremiumV2_LRS"
  create_option        = "Empty"
  zone                 = var.availability_zone_id

  disk_size_gb         = var.logs_disk_size_gb
  disk_mbps_read_write = var.logs_disk_throughput
  disk_iops_read_write = var.logs_disk_iops
  os_type              = "Windows"
}

# Attach Data Disks
resource "azurerm_virtual_machine_data_disk_attachment" "logs_disk_attachments" {
  count              = var.logs_disk_count
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  managed_disk_id    = azurerm_managed_disk.logs_disks[count.index].id
  lun                = var.data_disk_count + count.index
  caching            = "None"   # None for logs, per this page - https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/performance-guidelines-best-practices-storage?view=azuresql
}

resource "azurerm_mssql_virtual_machine" "sqlvm" {
  virtual_machine_id               = azurerm_windows_virtual_machine.vm.id
  sql_license_type                 = "AHUB"
  r_services_enabled               = false
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_username = var.sql_admin_username
  sql_connectivity_update_password = var.sql_admin_password

  auto_patching {
    day_of_week                            = "Sunday"
    maintenance_window_duration_in_minutes = 60
    maintenance_window_starting_hour       = 2
  }

  # key_vault_credential {
  #   name = "sqlvm-credential"
  #   key_vault_url = azurerm_key_vault.kv.vault_uri
  #   service_principal_name = azurerm_service_principal.sp.name
  #   service_principal_secret = azurerm_service_principal.sp.password
  # }

  assessment {
    enabled         = true
    run_immediately = false # true
  
    schedule {
      day_of_week        = "Monday"
      # monthly_occurrence = 0
      weekly_interval    = 1
      start_time         = "01:00"
    }
  }

  storage_configuration {
    disk_type = "NEW"
    storage_workload_type = "OLTP"
    system_db_on_data_disk_enabled = true

    temp_db_settings {
      default_file_path = "D:\\tempdb"
      luns = []
      data_file_count = 8
      data_file_size_mb = 8
      data_file_growth_in_mb = 64
      log_file_growth_mb = 8
      log_file_size_mb = 64
    }

    data_settings {
      default_file_path = "F:\\data"
      luns = [for x in azurerm_virtual_machine_data_disk_attachment.data_disk_attachments : x.lun]
    }

    log_settings {
      default_file_path = "G:\\log"
      luns = [for x in azurerm_virtual_machine_data_disk_attachment.logs_disk_attachments : x.lun]
    }
  }

  sql_instance {
    lock_pages_in_memory_enabled         = true
    adhoc_workloads_optimization_enabled = true
    instant_file_initialization_enabled  = true
  }
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "${var.base_name}-wksp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_workspace_table" "sqlbpa" {
  workspace_id            = azurerm_log_analytics_workspace.workspace.id
  name                    = "SqlAssessment_CL"
  retention_in_days       = 30
  total_retention_in_days = 30

  # depends_on = [ azurerm_log_analytics_workspace.workspace ]
}

resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                 = "${var.location}-DCE-1"    
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  kind                 = "Windows"
}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                 = "${azurerm_log_analytics_workspace.workspace.workspace_id}_${var.location}_DCR_1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name

  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id

  stream_declaration {
    stream_name = "Custom-SqlAssessment_CL"

    column {
      name = "TimeGenerated"
      type = "datetime"
    }
    column {
      name = "RawData"
      type = "string"
    }
  }

  data_sources {
    log_file {
      name          = "Custom-SqlAssessment_CL"
      streams       = ["Custom-SqlAssessment_CL"]
      format        = "text"
      file_patterns = ["C:\\Windows\\System32\\config\\systemprofile\\AppData\\Local\\Microsoft SQL Server IaaS Agent\\Assessment\\*.csv"]
      settings {
        text {
          record_start_timestamp_format = "ISO 8601"
        }
      }
    }
  }

  data_flow {
    streams      = ["Custom-SqlAssessment_CL"]
    destinations = [azurerm_log_analytics_workspace.workspace.name]
    transform_kql = "source"
    output_stream = "Custom-SqlAssessment_CL"
  }

  destinations {
    log_analytics {
      # workspace_resource_id = var.log_analytics_workspace_id
      workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
      name                  = azurerm_log_analytics_workspace.workspace.name
    }
  }

  # depends_on = [ azurerm_log_analytics_workspace_table.sqlbpa ]
}

# # Associate to a Data Collection Rule
# resource "azurerm_monitor_data_collection_rule_association" "dcea" {
#   name                        = "configurationAccessEndpoint"
#   target_resource_id          = azurerm_windows_virtual_machine.vm.id
#   data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id
#   # description             = "example"
# }

# Associate to a Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "dcra" {
  name                    = "${azurerm_log_analytics_workspace.workspace.workspace_id}_${var.location}_DCRA_1"
  target_resource_id      = azurerm_windows_virtual_machine.vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
  description             = "Association of data collection rule. Deleting this association will break the data collection for this SQL VM."
}

# resource "azurerm_key_vault" "kv" {
#   name                = "${var.base_name}-kv"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location

#   tenant_id           = data.azurerm_client_config.current.tenant_id
#   sku_name            = "standard"

#   enable_rbac_authorization = true
# }

# # TODO: Create an App Registration for the Key Vault access

# # Make the current Terraform user (whoever is runnign this script) a Key Vault Administrator so they can create secrets
# resource "azurerm_role_assignment" "kv_admin_role" {
#   role_definition_name = "Key Vault Administrator"
#   scope                = azurerm_key_vault.kv.id
#   principal_id         = azurerm_service_principal.sp.id
# }