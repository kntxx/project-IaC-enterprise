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
        log_levels     = ["Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency"] 
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

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "alert_heartbeat" {
  name                = "alert-${var.environment}-vm-heartbeat-missing"
  location            = var.location
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_log_analytics_workspace.law.id]

  description          = "Triggers when the Linux VM stops reporting health heartbeats for over 5 minutes."
  severity             = 1
  enabled              = true
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  criteria {
    query = <<-QUERY
      Heartbeat
    QUERY

    time_aggregation_method = "Count"
    

    resource_id_column      = "_ResourceId" 
    
    operator                = "LessThan"
    threshold               = 1

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods       = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.alert_notifications.id]
  }
}


resource "azurerm_monitor_scheduled_query_rules_alert_v2" "alert_cpu_spike" {
  name                = "alert-${var.environment}-cpu-spike"
  location            = var.location
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_log_analytics_workspace.law.id]

  description          = "Triggers if average CPU utilization exceeds 85%."
  
 
  severity             = 2 
  enabled              = true
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  criteria {
    query = <<-QUERY
      Perf
      | where ObjectName == "Processor" and CounterName == "% Processor Time"
      | summarize AggregatedValue = avg(CounterValue) by bin(TimeGenerated, 5m), _ResourceId
    QUERY

    time_aggregation_method = "Average"
    metric_measure_column   = "AggregatedValue"
    resource_id_column      = "_ResourceId"
    operator                = "GreaterThan"
    threshold               = 85

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods       = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.alert_notifications.id]
  }
}



resource "azurerm_monitor_scheduled_query_rules_alert_v2" "alert_ssh_failures" {
  name                = "alert-${var.environment}-ssh-brute-force"
  location            = var.location
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_log_analytics_workspace.law.id]

  description          = "Triggers if more than 5 failed SSH login attempts happen within 5 minutes."
  
 
  severity             = 1 
  
  enabled              = true
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  criteria {
    query = <<-QUERY
      Syslog
      | where Facility in ("auth", "authpriv")
      | where SyslogMessage has "failed" or SyslogMessage has "Invalid user"
    QUERY

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 5

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods       = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.alert_notifications.id]
  }
}