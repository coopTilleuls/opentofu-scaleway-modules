# From https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/guides/migration_guide_cockpit_plan
resource "scaleway_cockpit_source" "metrics" {
  project_id     = var.project_id
  region         = var.region
  name           = var.metrics_name
  type           = "metrics"
  retention_days = var.metrics_retention_days
}

resource "scaleway_cockpit_source" "logs" {
  project_id     = var.project_id
  region         = var.region
  name           = var.logs_name
  type           = "logs"
  retention_days = var.logs_retention_days
}

resource "scaleway_cockpit_source" "traces" {
  project_id     = var.project_id
  region         = var.region
  name           = var.traces_name
  type           = "traces"
  retention_days = var.traces_retention_days
}

data "scaleway_cockpit_preconfigured_alert" "all" {
  project_id = var.project_id
  region     = var.region
}

locals {
  # Rotation d'astreinte Les Tilleuls (Grafana OnCall), partagée entre projets clients.
  oncall_24_7 = "https://oncall-prod-eu-west-0.grafana.net/oncall/integrations/v1/alertmanager/REDACTED-ONCALL-TOKEN/"
  oncall_7_5  = "https://oncall-prod-eu-west-0.grafana.net/oncall/integrations/v1/alertmanager/REDACTED-ONCALL-TOKEN/"
  oncall_0_0  = "https://oncall-prod-eu-west-0.grafana.net/oncall/integrations/v1/alertmanager/REDACTED-ONCALL-TOKEN/"

  contact_points = {
    oncall_24_7 = {
      url = var.is_production ? local.oncall_24_7 : local.oncall_7_5
    }
    oncall_7_5 = {
      url = local.oncall_7_5
    }
    oncall_0_0 = {
      url = local.oncall_0_0
    }
  }


  # Optional in each alert :
  # - expression_regex_1 and expression_replacement_1
  # - expression_regex_2 and expression_replacement_2
  # - description_regex and description_replacement
  # - comparaison : if need to change comparaison operator


  predefined_alerts_usage = {
    # MySQL
    "Managed Databases - MySQL" = {
      "MySQLTooManyConnections" = {
        enabled = "false"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
      "MySQLHighCPULoad" = {
        enabled = "false"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
      "MySQLHighStorageUsage" = {
        enabled = "false"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
    }

    # PostgreSQL
    "Managed Databases - PostgreSQL" = {
      "PostgreSQLHighCPULoad" = {
        enabled                  = "true"
        expression_regex_1       = "/^/"
        expression_replacement_1 = "100 * ("
        expression_regex_2       = "/ > 0\\.8/"
        expression_replacement_2 = ")"
        description_regex        = "to 80% since 10m"
        description_replacement  = "to THRESHOLD% since DURATION"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "10m"
          critical = "3m"
        }
      }
      "PostgreSQLHighStorageUsage" = {
        enabled                  = "true"
        expression_regex_1       = "/^/"
        expression_replacement_1 = "100 * ("
        expression_regex_2       = "/ > 0\\.8/"
        expression_replacement_2 = ")"
        description_regex        = "to 80% since 10m"
        description_replacement  = "to THRESHOLD% since DURATION"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
      "PostgresqlTooManyConnections" = {
        enabled                  = "true"
        expression_regex_1       = "/^/"
        expression_replacement_1 = "100 * ("
        expression_regex_2       = "/ > 0\\.8/"
        expression_replacement_2 = ")"
        description_regex        = "to 80% since 10m"
        description_replacement  = "to THRESHOLD% since DURATION"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
    }

    # Redis
    "Managed Databases - Redis" = {
      "HighMemoryUsage" = {
        enabled = "false"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
      "HighCpuUsage" = {
        enabled = "false"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
    }

    "Serverless - SQL Databases" = {
      "ServerlessSQLDatabaseHighCPUUsage" = {
        enabled = "false"
      }
    }

    "Data & Analytics - Data Warehouse" = {
      # DataWarehouse
      "DataWarehouseHighCPUUsage" = {
        enabled = "false"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
    }

    "Load Balancer - LB" = {
      "LBHighBandwidthLoad" = {
        enabled = "true"
        # on remplace tout l'expression
        expression_regex_1       = "/^.*$/"
        expression_replacement_1 = "100 * avg by (instance, resource_name, resource_id, project_id, region) (load_balancer_lb_bandwidth_in_usage or load_balancer_lb_bandwidth_out_usage)"
        description_regex        = "to 80% since 10m"
        description_replacement  = "to THRESHOLD% since DURATION"
        threshold = {
          # tolerate lost of one network zone
          warning  = 80 / 2
          critical = 90 / 2
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
      "LBHighConnectionLoad" = {
        enabled                  = "true"
        expression_regex_1       = "/^/"
        expression_replacement_1 = "100 * ("
        expression_regex_2       = "/ > 0\\.8/"
        expression_replacement_2 = ")"
        description_regex        = "to 80% since 10m"
        description_replacement  = "to THRESHOLD% since DURATION"
        threshold = {
          # tolerate lost of one network zone
          warning  = 80 / 2
          critical = 90 / 2
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
      "LBHighCPULoad" = {
        enabled                  = "true"
        expression_regex_1       = "/^/"
        expression_replacement_1 = "100 * ("
        expression_regex_2       = "/ > 0\\.8/"
        expression_replacement_2 = ")"
        description_regex        = "to 80% since 10m"
        description_replacement  = "to THRESHOLD% since DURATION"
        threshold = {
          # tolerate lost of one network zone
          warning  = 80 / 2
          critical = 90 / 2
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
      "LBBackendServerDown" = {
        enabled                  = "true"
        expression_regex_1       = "/^.*$/"
        expression_replacement_1 = "load_balancer_lb_backend_agg_server_check_status{state=\"UP\", backend_name!=\"\"}"
        comparaison              = "<"
        threshold = {
          warning  = 2
          critical = 1
        }
        duration = {
          warning  = "10m"
          critical = "10m"
        }
      }
      "LBHighMemoryLoad" = {
        enabled                  = "true"
        expression_regex_1       = "/^/"
        expression_replacement_1 = "100 * ("
        expression_regex_2       = "/ > 0\\.8/"
        expression_replacement_2 = ")"
        description_regex        = "to 80% since 10m"
        description_replacement  = "to THRESHOLD% since DURATION"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
      "LBBackendDown" = {
        enabled                  = "true"
        expression_regex_1       = "/^.*$/"
        expression_replacement_1 = "avg by (instance, resource_name, resource_id, project_id, region, backend_name) (load_balancer_lb_backend_status{state=\"DOWN\", backend_name!=\"\"})"
        threshold = {
          warning  = 1
          critical = 1
        }
        duration = {
          warning  = "5m"
          critical = "10m"
        }
      }
    }

    "Containers - Kubernetes" = {
      # Kubernetes API
      "APIServerHighCPUUsage" = {
        enabled                  = "true"
        expression_regex_1       = "/^/"
        expression_replacement_1 = "100 * ("
        expression_regex_2       = "/ > 0\\.9/"
        expression_replacement_2 = ")"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "10m"
          critical = "30m"
        }
      }
      "APIServerHighMemoryUsage" = {
        enabled                  = "true"
        expression_regex_1       = "/^/"
        expression_replacement_1 = "100 * ("
        expression_regex_2       = "/ > 0\\.9/"
        expression_replacement_2 = ")"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }

      # Kubernetes nodes
      "NodesNotReady" = {
        enabled = "false"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
    }

    "Compute - Instance" = {
      "InstanceHighCPUUsage" = {
        enabled = "false"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
    }

    "ServerlessSQLDatabaseHighCPUUsage" = {
      enabled = "false"
      threshold = {
        warning  = 80
        critical = 90
      }
      duration = {
        warning  = "3m"
        critical = "3m"
      }
    }

    # Cockpit
    "Observability - Cockpit" = {
      "CockpitIngestionDecrease" = {
        enabled = "false"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
      "CockpitIngestionIncrease" = {
        enabled = "false"
        threshold = {
          warning  = 80
          critical = 90
        }
        duration = {
          warning  = "3m"
          critical = "3m"
        }
      }
    }
  }


  # Creation des alertes custom a partir de celles proposees par Scaleway
  # on les prend depuis data.scaleway_cockpit_preconfigured_alert.all
  # on les groupe par product_family - product_name
  # on les filtre fonction de predefined_alerts_usage, pour savoir celles qu'on garde ou pas, et comment on la patch pour les seuils warning/critical
  scaleway_cockpit_preconfigured_alert_groups = distinct([for alert in data.scaleway_cockpit_preconfigured_alert.all.alerts : "${alert.product_family} - ${alert.product_name}"])

  custom_rules_groups_from_predefined = [
    for group in local.scaleway_cockpit_preconfigured_alert_groups : {
      name = group
      rules = [
        for alert in data.scaleway_cockpit_preconfigured_alert.all.alerts : {
          name      = alert.name
          threshold = local.predefined_alerts_usage[group][alert.name].threshold
          duration  = local.predefined_alerts_usage[group][alert.name].duration
          # patch rule avec regex prefix et suffix: "100 * (" et remplacer "> 0.8" par ")" pour l'avoir en pourcentage, et pour enlever l'operateur de comparaison et le seuil qu'on passe separement
          expression = replace(
            replace(
              alert.rule,
              try(local.predefined_alerts_usage[group][alert.name].expression_regex_1, "/do_not_match/"),
              try(local.predefined_alerts_usage[group][alert.name].expression_replacement_1, "SHOULD_NOT_BE_USED")
            ),
            try(local.predefined_alerts_usage[group][alert.name].expression_regex_2, "/do_not_match/"),
            try(local.predefined_alerts_usage[group][alert.name].expression_replacement_2, "SHOULD_NOT_BE_USED")
          )
          annotations = alert.annotations
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/${replace(group, "/[^a-zA-Z]/", "")}/${replace(alert.name, "/[^a-zA-Z]/", "")}"
          # patch description avec regex "to THRESHOLD% since DURATION"
          description = replace(
            alert.annotations.description,
            try(local.predefined_alerts_usage[group][alert.name].description_regex, "/do_not_match/"),
            try(local.predefined_alerts_usage[group][alert.name].description_replacement, "SHOULD_NOT_BE_USED")
          )
          comparaison = try(local.predefined_alerts_usage[group][alert.name].comparaison, regex("( )(>|>=|<|<=|=)( )", alert.rule)[1])
        } if(alert.product_family == split(" - ", group)[0])
        && (alert.product_name == split(" - ", group)[1])
        && (local.predefined_alerts_usage[group][alert.name].enabled == "true")
      ]
    }
  ]

  all_custom_rules_groups = concat(local.custom_rules_groups_from_predefined, var.custom_rules_groups)
}

# La configuration d'alert manager se fait via le provider mimir :
resource "mimir_alertmanager_config" "this" {
  # TODO: routes, subroutes, group_by…

  route {
    receiver = "oncall_0_0"

    // see https://www.robustperception.io/whats-the-difference-between-group_interval-group_wait-and-repeat_interval/
    // we set prometheus default values: https://prometheus.io/docs/alerting/latest/configuration/
    group_by        = ["..."]
    group_wait      = "30s"
    group_interval  = "5m"
    repeat_interval = "4h"

    child_route {
      matchers = [
        "severity=\"warning\"",
      ]
      receiver        = "oncall_7_5"
      group_wait      = "30s"
      group_interval  = "5m"
      repeat_interval = "1h"
    }

    child_route {
      matchers = [
        "severity=\"critical\"",
      ]
      receiver        = "oncall_24_7"
      group_wait      = "30s"
      group_interval  = "5m"
      repeat_interval = "20m"
    }
  }

  dynamic "receiver" {
    for_each = local.contact_points
    content {
      name = receiver.key
      webhook_configs {
        send_resolved = true
        url           = receiver.value["url"]
      }
    }
  }
}

# Les alertes se configurent via des alerting rules, generees a partir des alertes
# preconfigurees Scaleway (cf. local.predefined_alerts_usage) et des regles custom
# passees par l'appelant (cf. var.custom_rules_groups).
resource "mimir_rule_group_alerting" "custom_rules" {
  for_each = { for group in local.all_custom_rules_groups : group.name => group if length(group.rules) > 0 }
  name     = replace("Custom Rules - ${each.value.name}", "/[^a-zA-Z0-9-_.]/", "_")

  dynamic "rule" {
    for_each = { for rule in flatten([
      for severity in ["warning", "critical"] : [
        for rule in each.value.rules : merge(
          {
            severity = severity
          },
          rule
        )
      ]
    ]) : "${rule.name}-${rule.severity}" => rule }
    content {
      alert = replace("${each.value.name} - ${rule.value.name} - ${rule.value.severity}", "/[^a-zA-Z0-9-_.]/", "_")
      expr  = "${rule.value.expression} ${rule.value.comparaison} ${rule.value.threshold[rule.value.severity]}"
      for   = rule.value.duration[rule.value.severity]

      labels = merge(
        try(rule.value.labels, {}),
        {
          severity = rule.value.severity
        }
      )
      annotations = merge(
        try(rule.value.annotations, {}),
        {
          summary     = replace(replace(rule.value.annotations.summary, "THRESHOLD", rule.value.threshold[rule.value.severity]), "DURATION", rule.value.duration[rule.value.severity])
          description = replace(replace(rule.value.description, "THRESHOLD", rule.value.threshold[rule.value.severity]), "DURATION", rule.value.duration[rule.value.severity])
          runbook_url = rule.value.runbook_url
          terraformed = "true"
        }
      )
    }
  }
}
