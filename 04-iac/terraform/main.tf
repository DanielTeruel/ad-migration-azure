resource "azurerm_resource_group" "res-0" {
  location = "francecentral"
  name     = "rg-daniellab-v3"
  tags = {
    Environment = "Lab"
    Proyecto    = "Fase10"
  }
}
resource "azurerm_windows_virtual_machine" "res-1" {
  admin_password        = "XXXXXXXXXXXXXXXX"
  admin_username        = "sqladmin"
  location              = "francecentral"
  name                  = "vm-sql01"
  network_interface_ids = [azurerm_network_interface.res-6.id]
  resource_group_name   = azurerm_resource_group.res-0.name
  size                  = "Standard_D2s_v3"

  boot_diagnostics {
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  lifecycle {
    ignore_changes = [admin_password]
  }
}
resource "azurerm_application_insights" "res-2" {
  application_type    = "web"
  location            = "francecentral"
  name                = "ai-daniellab"
  resource_group_name = azurerm_resource_group.res-0.name
  sampling_percentage = 0
  workspace_id        = azurerm_log_analytics_workspace.res-12.id

  timeouts {
    create = "30m"
  }
}
resource "azurerm_monitor_metric_alert" "res-3" {
  auto_mitigate       = false
  description         = "Alerta cuando la CPU de vm-sql01 supera el 80% durante 1 minuto"
  name                = "alert-cpu-vm-sql01"
  resource_group_name = azurerm_resource_group.res-0.name
  scopes              = [azurerm_windows_virtual_machine.res-1.id]
  severity            = 2
  window_size         = "PT1M"
  action {
    action_group_id = "/subscriptions/e6715b57-fcfb-4f50-9b7f-53d94ca72561/resourceGroups/rg-daniellab-v3/providers/microsoft.insights/actionGroups/Application Insights Smart Detection"
  }
  criteria {
    aggregation      = "Average"
    metric_name      = "Percentage CPU"
    metric_namespace = "Microsoft.Compute/virtualMachines"
    operator         = "GreaterThan"
    threshold        = 80
  }
}
resource "azurerm_key_vault" "res-4" {
  location            = "francecentral"
  name                = "kv-daniellab-2603"
  resource_group_name = azurerm_resource_group.res-0.name
  sku_name            = "standard"
  tenant_id           = "8799ccb4-1532-4247-a0a1-7b2e74062950"
}
resource "azurerm_bastion_host" "res-5" {
  location            = "francecentral"
  name                = "bastion-daniellab"
  resource_group_name = azurerm_resource_group.res-0.name
  sku                 = "Developer"
  virtual_network_id  = azurerm_virtual_network.res-8.id
}
resource "azurerm_network_interface" "res-6" {
  location            = "francecentral"
  name                = "vm-sql01VMNic"
  resource_group_name = azurerm_resource_group.res-0.name

  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"  
    subnet_id                     = azurerm_subnet.res-10.id
  }

  depends_on = [
    azurerm_subnet.res-10,
  ]
}
resource "azurerm_network_security_group" "res-7" {
  location            = "francecentral"
  name                = "nsg-sql"
  resource_group_name = azurerm_resource_group.res-0.name
}
resource "azurerm_virtual_network" "res-8" {
  address_space       = ["10.0.0.0/16"]
  location            = "francecentral"
  name                = "vnet-daniellab-2603"
  resource_group_name = azurerm_resource_group.res-0.name
}
resource "azurerm_subnet" "res-9" {
  address_prefixes     = ["10.0.2.0/27"]
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.res-0.name
  virtual_network_name = "vnet-daniellab-2603"
  depends_on = [
    azurerm_virtual_network.res-8,
  ]
}
resource "azurerm_subnet" "res-10" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "snet-default"
  resource_group_name  = azurerm_resource_group.res-0.name
  virtual_network_name = "vnet-daniellab-2603"
  depends_on = [
    azurerm_virtual_network.res-8,
  ]
}
resource "azurerm_subnet_network_security_group_association" "res-11" {
  network_security_group_id = azurerm_network_security_group.res-7.id
  subnet_id                 = azurerm_subnet.res-10.id
}
resource "azurerm_log_analytics_workspace" "res-12" {
  location            = "francecentral"
  name                = "law-daniellab"
  resource_group_name = azurerm_resource_group.res-0.name
}

resource "azurerm_recovery_services_vault" "res-688" {
  location            = "francecentral"
  name                = "rsv-daniellab"
  resource_group_name = azurerm_resource_group.res-0.name
  sku                 = "RS0"
}
resource "azurerm_backup_policy_vm" "res-689" {
  name                = "DefaultPolicy"
  recovery_vault_name = "rsv-daniellab"
  resource_group_name = azurerm_resource_group.res-0.name
  backup {
    frequency = "Daily"
    time      = "23:00"
  }
  retention_daily {
    count = 30
  }
  depends_on = [
    azurerm_recovery_services_vault.res-688,
  ]
}
resource "azurerm_backup_policy_vm" "res-690" {
  name                = "EnhancedPolicy"
  policy_type         = "V2"
  recovery_vault_name = "rsv-daniellab"
  resource_group_name = azurerm_resource_group.res-0.name
  backup {
    frequency     = "Hourly"
    hour_duration = 12
    hour_interval = 4
    time          = "08:00"
  }
  retention_daily {
    count = 30
  }
  depends_on = [
    azurerm_recovery_services_vault.res-688,
  ]
}
resource "azurerm_backup_policy_vm_workload" "res-691" {
  name                = "HourlyLogBackup"
  recovery_vault_name = "rsv-daniellab"
  resource_group_name = azurerm_resource_group.res-0.name
  workload_type       = "SQLDataBase"
  protection_policy {
    policy_type = "Log"
    backup {
      frequency_in_minutes = 60
    }
    simple_retention {
      count = 30
    }
  }
  protection_policy {
    policy_type = "Full"
    backup {
      frequency = "Daily"
      time      = "23:00"
    }
    retention_daily {
      count = 30
    }
  }
  settings {
    time_zone = "UTC"
  }
  depends_on = [
    azurerm_recovery_services_vault.res-688,
  ]
}
resource "azurerm_storage_account" "res-694" {
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  allow_nested_items_to_be_public = false
  location                        = "francecentral"
  name                            = "stbkp2603qprhr"
  resource_group_name             = azurerm_resource_group.res-0.name
}
resource "azurerm_storage_account_queue_properties" "res-697" {
  storage_account_id = azurerm_storage_account.res-694.id
  hour_metrics {
    version = "1.0"
  }
  logging {
    delete  = false
    read    = false
    version = "1.0"
    write   = false
  }
  minute_metrics {
    version = "1.0"
  }
}
resource "azurerm_storage_account" "res-699" {
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  allow_nested_items_to_be_public = false
  location                        = "francecentral"
  name                            = "stfiles2603qprh"
  resource_group_name             = azurerm_resource_group.res-0.name
}
resource "azurerm_storage_account_queue_properties" "res-702" {
  storage_account_id = azurerm_storage_account.res-699.id
  hour_metrics {
    version = "1.0"
  }
  logging {
    delete  = false
    read    = false
    version = "1.0"
    write   = false
  }
  minute_metrics {
    version = "1.0"
  }
}
resource "azurerm_service_plan" "res-704" {
  location            = "francecentral"
  name                = "asp-daniellab"
  os_type             = "Linux"
  resource_group_name = azurerm_resource_group.res-0.name
  sku_name            = "B1"
}
resource "azurerm_linux_web_app" "res-705" {
  client_affinity_enabled = true
  https_only              = true
  location                = "francecentral"
  name                    = "app-daniellab-2603"
  resource_group_name     = azurerm_resource_group.res-0.name
  service_plan_id         = azurerm_service_plan.res-704.id
  auth_settings {
    enabled                       = false
    token_refresh_extension_hours = 0
  }
  identity {
    type = "SystemAssigned"
  }
  site_config {
    always_on                         = false
    http2_enabled                     = true
    ip_restriction_default_action     = "Allow"
    scm_ip_restriction_default_action = "Allow"
  }
}
resource "azurerm_monitor_smart_detector_alert_rule" "res-710" {
  description         = "Failure Anomalies notifica cuando la tasa de errores de la app aumenta de forma anómala"
  detector_type       = "FailureAnomaliesDetector"
  frequency           = "PT1M"
  name                = "failure-anomalies-ai-daniellab"
  resource_group_name = azurerm_resource_group.res-0.name
  scope_resource_ids  = ["/subscriptions/e6715b57-fcfb-4f50-9b7f-53d94ca72561/resourcegroups/rg-daniellab-v3/providers/microsoft.insights/components/ai-daniellab"]
  severity            = "Sev3"
  action_group {
    ids = [azurerm_monitor_action_group.res-711.id]
  }
}
resource "azurerm_monitor_action_group" "res-711" {
  name                = "Application Insights Smart Detection"
  resource_group_name = azurerm_resource_group.res-0.name
  short_name          = "SmartDetect"
}

