resource "azurerm_log_analytics_workspace" "law" {
  name                = var.workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "dcr-${var.environment}-monitoring-01"
  resource_group_name = var.resource_group_name
  location            = var.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
      name                  = "central-law"
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Syslog"]
    destinations = ["central-law"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\LogicalDisk(_Total)\\% Free Space"
      ]
      name                          = "vm-perf-counters"
    }

    syslog {
      streams        = ["Microsoft-Syslog"]
      facility_names = ["auth", "authpriv"]
      log_levels     = ["Warning", "Error", "Critical", "Alert", "Emergency"]
      name           = "vm-security-logs"
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "dcra" {
  name                    = "dcra-${var.environment}-vm-association"
  target_resource_id      = var.vm_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
}

resource "azurerm_monitor_action_group" "alert_notifications" {
  name                = "ag-${var.environment}-alerts-01"
  resource_group_name = var.resource_group_name
  short_name          = "ops-alerts"


  email_receiver {
    name                    = "kent"
    email_address           = "kentatixx@gmail.com" 
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "alert_heartbeat" {
  name                = "alert-${var.environment}-vm-heartbeat-missing"
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.alert_notifications.id]
  }

  data_source_id = azurerm_log_analytics_workspace.law.id
  description    = "Triggers when the Linux VM stops reporting health heartbeats for over 5 minutes."
  enabled        = true
  
  # Check every 5 minutes looking back over the last 5 minutes
  frequency   = 5
  time_window = 5

  # KQL: If count is 0, the agent has stopped talking to Azure Monitor
  query       = <<-QUERY
    Heartbeat
    | summarize LastHeartbeat = max(TimeGenerated) by Computer
    | where LastHeartbeat < ago(5m)
  QUERY

  trigger {
    operator  = "GreaterThanOrEqual"
    threshold = 1
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "alert_cpu_spike" {
  name                = "alert-${var.environment}-cpu-spike"
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.alert_notifications.id]
  }

  data_source_id = azurerm_log_analytics_workspace.law.id
  description    = "Triggers if average CPU utilization exceeds 85%."
  enabled        = true
  frequency      = 5
  time_window    = 5


  query       = <<-QUERY
    Perf
    | where ObjectName == "Processor" and CounterName == "% Processor Time"
    | summarize AggregatedValue = avg(CounterValue) by Computer
  QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = 85
  }
}

# 3. Alert 2: Failed SSH Attempts (Security Brute Force)
resource "azurerm_monitor_scheduled_query_rules_alert" "alert_ssh_failures" {
  name                = "alert-${var.environment}-ssh-brute-force"
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.alert_notifications.id]
  }

  data_source_id = azurerm_log_analytics_workspace.law.id
  description    = "Triggers if more than 5 failed SSH login attempts happen within 5 minutes."
  enabled        = true
  frequency      = 5
  time_window    = 5

  # KQL: Scans syslog facility for authentication drops or password rejections
  query       = <<-QUERY
    Syslog
    | where Facility in ("auth", "authpriv")
    | where SyslogMessage has "failed" or SyslogMessage has "Invalid user"
    | summarize FailedCount = count() by Computer
  QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = 5
  }
}