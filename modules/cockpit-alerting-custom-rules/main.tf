locals {
  # Filtre PromQL sur la ressource surveillée, vide si var.resource_name est null :
  # - selector      : pour un sélecteur sans autre label, ex. metric{${local.selector}}
  # - and_selector  : pour un sélecteur qui a déjà des labels, ex. metric{type="size"${local.and_selector}}
  selector     = var.resource_name == null ? "" : "resource_name=\"${var.resource_name}\""
  and_selector = var.resource_name == null ? "" : ",resource_name=\"${var.resource_name}\""

  public_gateway_bandwidth_mbps = {
    "S"  = 100,
    "M"  = 1000,
    "L"  = 3000,
    "XL" = 10000
  }
  # 0 si public_gateway_size est null : jamais utilisé dans ce cas, cf. precondition
  public_gateway_bandwidth_bytes = try(local.public_gateway_bandwidth_mbps[var.public_gateway_size], 0) * 1000 * 1000 / 8

  # in summary or description: THRESHOLD and DURATION are replaced by their values
  rules_groups = {
    kubernetes = {
      name = "Kubernetes"
      rules = [
        {
          name = "ETCD Disk Quota"
          threshold = {
            # en %
            warning  = 80
            critical = 90
          }
          duration = {
            warning  = "10m"
            critical = "10m"
          }
          expression  = "avg by(resource_name) (100 * kubernetes_cluster_etcdwatcher_namespace_usage{type=\"size\"${local.and_selector}} / kubernetes_cluster_etcdwatcher_namespace_quota{type=\"size\"${local.and_selector}})"
          comparaison = ">"
          annotations = {
            summary = "High ETCD disk quota on {{ $labels.resource_name }} Kubernetes cluster."
          }
          description = "ETCD service of {{ $labels.resource_name }} Kubernetes API has a disk usage superior to THRESHOLD% since DURATION"
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/CustomETCD/DiskQuota"
        },
        {
          name = "ETCD CPU Usage"
          threshold = {
            # en %
            warning  = 60
            critical = 80
          }
          duration = {
            warning  = "10m"
            critical = "10m"
          }
          # when controle plane is dedicated 4, no cpu limit, so default to 4 in usage calculation
          expression  = "avg by (resource_name) (100 * (kubernetes_cluster_k8s_shoot_controlplane_cpu_usage{component=\"api-server\"${local.and_selector}} / kubernetes_cluster_k8s_shoot_controlplane_cpu_limit{component=\"api-server\"${local.and_selector}}) or (kubernetes_cluster_k8s_shoot_controlplane_cpu_usage{component=\"api-server\"${local.and_selector}} / 4))"
          comparaison = ">"
          annotations = {
            summary = "High ETCD cpu usage on {{ $labels.resource_name }} Kubernetes cluster."
          }
          description = "ETCD service of {{ $labels.resource_name }} Kubernetes API has a CPU usage superior to THRESHOLD% since DURATION"
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/CustomETCD/CpuUsage"
        },
      ]
    }

    s2s_vpn = {
      name = "S2S VPN"
      rules = [
        {
          name = "Inbound bandwitch"
          threshold = {
            # en %
            warning  = 80 / 2
            critical = 90 / 2
          }
          duration = {
            warning  = "10m"
            critical = "10m"
          }
          expression  = "100 * sum by(resource_name) (rate(svpn_gateway_tunnel_received_bytes_count{${local.selector}}[5m])) / avg by(resource_name) (svpn_gateway_bandwidth_capacity_bps{${local.selector}})"
          comparaison = ">"
          annotations = {
            summary = "High S2S VPN Inbound bandwidth on {{ $labels.resource_name }} VPN."
          }
          description = "S2S VPN Inbound bandwith on {{ $labels.resource_name }} is superior to THRESHOLD% since DURATION. The threshold is based on zone disturbtion tolerance."
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/CustomS2SVPN/InboundBandwidth"
        },
        {
          name = "Outbound bandwitch"
          threshold = {
            # en %
            warning  = 80 / 2
            critical = 90 / 2
          }
          duration = {
            warning  = "10m"
            critical = "10m"
          }
          expression  = "100 * sum by(resource_name) (rate(svpn_gateway_tunnel_sent_bytes_count{${local.selector}}[5m])) / avg by(resource_name) (svpn_gateway_bandwidth_capacity_bps{${local.selector}})"
          comparaison = ">"
          annotations = {
            summary = "High S2S VPN Outbound bandwidth on {{ $labels.resource_name }} VPN."
          }
          description = "S2S VPN Outbound bandwith on {{ $labels.resource_name }} is superior to THRESHOLD% since DURATION. The threshold is based on zone disturbtion tolerance."
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/CustomS2SVPN/OutboundBandwidth"
        },
      ]
    }

    public_gateway = {
      name = "Public Gateway"
      rules = [
        {
          name = "Inbound bandwitch"
          threshold = {
            # en %
            warning  = 80 / 2
            critical = 90 / 2
          }
          duration = {
            warning  = "10m"
            critical = "10m"
          }
          expression  = "100 * irate(public_gateway_receive_bytes_total{${local.selector}}[5m]) / ${local.public_gateway_bandwidth_bytes}"
          comparaison = ">"
          annotations = {
            summary = "High Public Gateway Inbound bandwidth on {{ $labels.resource_name }} VPN."
          }
          description = "Public Gateway Inbound bandwith on {{ $labels.resource_name }} is superior to THRESHOLD% since DURATION. The threshold is based on zone disturbtion tolerance."
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/CustomPublicGateway/InboundBandwidth"
        },
        {
          name = "Outbound bandwitch"
          threshold = {
            # en %
            warning  = 80 / 2
            critical = 90 / 2
          }
          duration = {
            warning  = "10m"
            critical = "10m"
          }
          expression  = "100 * irate(public_gateway_transmit_bytes_total{${local.selector}}[5m]) / ${local.public_gateway_bandwidth_bytes}"
          comparaison = ">"
          annotations = {
            summary = "High Public Gateway Outbound bandwidth on {{ $labels.resource_name }} VPN."
          }
          description = "Public Gateway Outbound bandwith on {{ $labels.resource_name }} is superior to THRESHOLD% since DURATION. The threshold is based on zone disturbtion tolerance."
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/CustomPublicGateway/OutboundBandwidth"
        },
      ]
    }

    postgresql = {
      name = "PostgreSQL"
      rules = [
        {
          name = "Memory"
          threshold = {
            # en %
            warning  = 80
            critical = 90
          }
          duration = {
            warning  = "10m"
            critical = "20m"
          }
          # TODO revoir
          expression  = "100 - ((rdb_instance_postgresql_node_memory_MemAvailable_bytes{${local.selector}} * 100) / rdb_instance_postgresql_node_memory_MemTotal_bytes{${local.selector}})"
          comparaison = ">"
          annotations = {
            summary = "High Memory usage on RDB PostgreSQL™ {{ $labels.resource_name }} cluster."
          }
          description = "PostgreSQL™ {{ $labels.instance }} node on instance {{ $labels.resource_name }} - {{ $labels.resource_id }} has a memory usage superior to THRESHOLD% since DURATION"
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/CustomPostgreSQL/Memory"
        },
      ]
    }

    opensearch = {
      name = "OpenSearch"
      rules = [
        {
          name = "CPU"
          threshold = {
            # en %
            warning  = 80
            critical = 90
          }
          duration = {
            warning  = "10m"
            critical = "20m"
          }
          expression  = "avg by(node, service) (sedb_deployment_opensearch_process_cpu_percent{${local.selector}})"
          comparaison = ">"
          annotations = {
            summary = "High CPU usage on node {{ $labels.node }} of OpenSearch cluster."
          }
          description = "OpenSearch node {{ $labels.node }} has a CPU usage superior to THRESHOLD% since DURATION"
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/CustomOpenSearch/CPU"
        },
        # Disabled until case 1616390 answer : this is not the good metric
        #{
        #  name = "Memory"
        #  threshold = {
        #    # en %
        #    warning  = 90
        #    critical = 95
        #  }
        #  duration = {
        #    warning  = "10m"
        #    critical = "20m"
        #  }
        #  expression  = "100 - sedb_deployment_opensearch_os_mem_free_percent{${local.selector}}"
        #  comparaison = ">"
        #  annotations = {
        #    summary = "High Memory usage on node {{ $labels.node }} of OpenSearch cluster {{ $labels.resource_name }} service {{ $labels.service }}."
        #  }
        #  description = "OpenSearch node {{ $labels.node }} of cluster {{ $labels.resource_name}}, for service {{ $labels.service }},  has a Memory usage superior to THRESHOLD% since DURATION"
        #  runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/CustomOpenSearch/Memory"
        #},
        {
          name = "Load average"
          threshold = {
            # en %
            warning  = 3
            critical = 5
          }
          duration = {
            warning  = "10m"
            critical = "10m"
          }
          expression  = "sedb_deployment_opensearch_os_load_average_five_minutes{${local.selector}}"
          comparaison = ">"
          annotations = {
            summary = "High Load average usage on node {{ $labels.node }} of OpenSearch cluster."
          }
          description = "OpenSearch node {{ $labels.node }} has a Load average usage superior to THRESHOLD% since DURATION"
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/CustomOpenSearch/LoadAverage"
        },
        # TODO: en attente case scaleway pour metrique utilisation disque
      ]
    }
  }

  # Alertes préconfigurées Scaleway ajoutées au jeu de règles du type, par nom d'alerte, et patchées
  # comme dans le module cockpit-alerting (mêmes seuils/durées) pour les avoir en pourcentage avec
  # des seuils warning/critical. Seules les alertes listées sont gardées. Pour ne pas les avoir en
  # double, les exclure de cockpit-alerting via exclude_predefined_rules.
  #
  # Optional in each alert :
  # - expression_regex_1 and expression_replacement_1
  # - expression_regex_2 and expression_replacement_2
  # - description_regex and description_replacement
  # - comparaison : if need to change comparaison operator
  predefined_alerts_usage = {
    postgresql = {
      group = "Managed Databases - PostgreSQL"
      alerts = {
        "PostgreSQLHighCPULoad" = {
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
    }
  }

  predefined = lookup(local.predefined_alerts_usage, var.type, null)

  # Les expressions Scaleway ne suivent pas un format commun (sélecteur avec ou sans labels) : au
  # lieu d'y injecter local.selector, on filtre le résultat sur resource_name par une jointure avec
  # un vecteur constant portant ce seul label. Toutes les alertes préconfigurées gardent le label
  # resource_name dans leur résultat. Parenthèses externes : l'opérateur de comparaison ajouté
  # ensuite est prioritaire sur "and".
  predefined_filter = var.resource_name == null ? null : "and on(resource_name) label_replace(vector(1), \"resource_name\", \"${var.resource_name}\", \"\", \"\")"

  rules_from_predefined = local.predefined == null ? [] : [
    for alert in data.scaleway_cockpit_preconfigured_alert.this[0].alerts : {
      name      = alert.name
      threshold = local.predefined.alerts[alert.name].threshold
      duration  = local.predefined.alerts[alert.name].duration
      # patch rule avec regex prefix et suffix: "100 * (" et remplacer "> 0.8" par ")" pour l'avoir en pourcentage, et pour enlever l'operateur de comparaison et le seuil qu'on passe separement
      expression = format(
        local.predefined_filter == null ? "%s" : "((%s) ${local.predefined_filter})",
        replace(
          replace(
            alert.rule,
            try(local.predefined.alerts[alert.name].expression_regex_1, "/do_not_match/"),
            try(local.predefined.alerts[alert.name].expression_replacement_1, "SHOULD_NOT_BE_USED")
          ),
          try(local.predefined.alerts[alert.name].expression_regex_2, "/do_not_match/"),
          try(local.predefined.alerts[alert.name].expression_replacement_2, "SHOULD_NOT_BE_USED")
        )
      )
      annotations = alert.annotations
      # même runbook que les alertes créées par cockpit-alerting
      runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/${replace(local.predefined.group, "/[^a-zA-Z]/", "")}/${replace(alert.name, "/[^a-zA-Z]/", "")}"
      # patch description avec regex "to THRESHOLD% since DURATION"
      description = replace(
        alert.annotations.description,
        try(local.predefined.alerts[alert.name].description_regex, "/do_not_match/"),
        try(local.predefined.alerts[alert.name].description_replacement, "SHOULD_NOT_BE_USED")
      )
      comparaison = try(local.predefined.alerts[alert.name].comparaison, regex("( )(>|>=|<|<=|=)( )", alert.rule)[1])
    } if "${alert.product_family} - ${alert.product_name}" == local.predefined.group
    && contains(keys(local.predefined.alerts), alert.name)
  ]

  group = {
    name  = local.rules_groups[var.type].name
    rules = concat(local.rules_groups[var.type].rules, local.rules_from_predefined)
  }
  group_name = "${local.group.name} - ${coalesce(var.resource_name, "all")}"
}

# Uniquement pour les types qui reprennent des alertes préconfigurées (cf. predefined_alerts_usage)
data "scaleway_cockpit_preconfigured_alert" "this" {
  count = local.predefined == null ? 0 : 1

  project_id = var.project_id
  region     = var.region
}

resource "mimir_rule_group_alerting" "this" {
  name = replace("Custom Rules - ${local.group_name}", "/[^a-zA-Z0-9-_.]/", "_")

  dynamic "rule" {
    for_each = { for rule in flatten([
      for severity in ["warning", "critical"] : [
        for rule in local.group.rules : merge(
          {
            severity = severity
          },
          rule
        )
      ]
    ]) : "${rule.name}-${rule.severity}" => rule }
    content {
      alert = replace("${local.group_name} - ${rule.value.name} - ${rule.value.severity}", "/[^a-zA-Z0-9-_.]/", "_")
      expr  = "${rule.value.expression} ${rule.value.comparaison} ${rule.value.threshold[rule.value.severity]}"
      for   = rule.value.duration[rule.value.severity]

      labels = merge(
        var.labels,
        {
          severity      = rule.value.severity
          service_level = var.service_level
        }
      )
      annotations = merge(
        rule.value.annotations,
        {
          summary     = replace(replace(rule.value.annotations.summary, "THRESHOLD", rule.value.threshold[rule.value.severity]), "DURATION", rule.value.duration[rule.value.severity])
          description = replace(replace(rule.value.description, "THRESHOLD", rule.value.threshold[rule.value.severity]), "DURATION", rule.value.duration[rule.value.severity])
          runbook_url = rule.value.runbook_url
          terraformed = "true"
        }
      )
    }
  }

  lifecycle {
    precondition {
      condition     = var.type != "public_gateway" || var.public_gateway_size != null
      error_message = "public_gateway_size est obligatoire quand type = \"public_gateway\"."
    }
  }
}
