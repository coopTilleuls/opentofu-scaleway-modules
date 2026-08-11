# cockpit-alerting

Crée les sources Cockpit Scaleway (`scaleway_cockpit_source` metrics/logs/traces)
et configure l'alerting Mimir associé : reprend chaque alerte préconfigurée
Scaleway (`data.scaleway_cockpit_preconfigured_alert`), la filtre/patch via une
table interne (`predefined_alerts_usage` — seuils warning/critical, expression,
etc.), la fusionne avec des règles custom propres à l'appelant, et route le
tout vers des webhooks Alertmanager fournis par l'appelant
(`webhook_url_info`/`webhook_url_warning`/`webhook_url_critical`) via
`mimir_alertmanager_config`. Ces webhooks peuvent pointer vers n'importe quel
système d'alerte exposant un endpoint Alertmanager (Grafana OnCall, PagerDuty,
Opsgenie, etc.) — le module ne dépend d'aucun système en particulier.
Motif dupliqué à l'identique entre plusieurs repos clients avant extraction
ici.

## Exemple

```hcl
# Ressources de bootstrap Cockpit qui restent dans le repo appelant (voir Remarques) : le
# provider mimir doit être configuré à partir de leurs attributs, donc elles ne peuvent pas
# être dans ce module.
resource "scaleway_cockpit_token" "terraform" {
  project_id = var.project_id
  name       = "terraform_${terraform.workspace}"
  scopes {
    setup_alerts        = true
    setup_metrics_rules = true
    write_metrics       = false
    write_logs          = false
  }
}

resource "scaleway_cockpit_alert_manager" "alert_manager" {
  project_id = var.project_id
}

module "cockpit_alerting" {
  source = "git::https://<repo-url>//modules/cockpit-alerting?ref=cockpit-alerting-vX.Y.Z"

  project_id    = var.project_id
  region        = var.scw_region
  is_production = terraform.workspace == "prod"

  # sensible : à passer via TF_VAR_webhook_url_* ou un backend de secrets, jamais en dur
  webhook_url_critical = var.webhook_url_critical
  webhook_url_warning  = var.webhook_url_warning
  webhook_url_info     = var.webhook_url_info

  # optionnel, valeurs par défaut ci-dessous
  metrics_retention_days = 6
  logs_retention_days    = 30
  traces_retention_days  = 15

  # optionnel, valeurs par défaut ci-dessous ; à surcharger uniquement pour importer une source
  # préexistante sans recréation (rappel : `name` est ForceNew côté provider Scaleway)
  metrics_name = "metrics-source"
  logs_name    = "logs-source"
  traces_name  = "traces-source"

  custom_rules_groups = [
    {
      name = "Custom - PostgreSQL"
      rules = [
        {
          name        = "Memory"
          threshold   = { warning = 80, critical = 90 }
          duration    = { warning = "10m", critical = "20m" }
          expression  = "100 - ((rdb_instance_postgresql_node_memory_MemAvailable_bytes{} * 100) / rdb_instance_postgresql_node_memory_MemTotal_bytes{})"
          comparaison = ">"
          annotations = { summary = "High Memory usage on RDB PostgreSQL™ {{ $labels.resource_name }} cluster." }
          description = "PostgreSQL™ {{ $labels.instance }} node on instance {{ $labels.resource_name }} - {{ $labels.resource_id }} has a memory usage superior to THRESHOLD% since DURATION"
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/Cloudproviders/Scaleway/Monitoring/IRP/CustomPostgreSQL/Memory"
        },
      ]
    }
  ]
}

# Le provider mimir référence une sortie de ce module (metrics_source_url) : voir Remarques
# pour pourquoi ça ne crée pas de cycle malgré le fait que ce module utilise lui-même mimir.
provider "mimir" {
  ruler_uri        = "${module.cockpit_alerting.metrics_source_url}/prometheus"
  alertmanager_uri = scaleway_cockpit_alert_manager.alert_manager.alert_manager_url
  org_id           = scaleway_cockpit_token.terraform.secret_key

  overwrite_alertmanager_config = true
  overwrite_rule_group_config   = true
}
```

## Remarques

- **`scaleway_cockpit_token` et `scaleway_cockpit_alert_manager` (+
  `data.scaleway_cockpit_grafana`) restent volontairement dans le repo
  appelant, pas dans ce module.** Le provider `mimir` doit être configuré
  (`alertmanager_uri`, `org_id`) à partir de leurs attributs ; comme ce
  module utilise lui-même le provider `mimir` (pour `mimir_alertmanager_config`
  et `mimir_rule_group_alerting`), le bloc `provider "mimir" {}` de l'appelant
  ne peut dépendre que de ressources qui n'utilisent **pas** ce même provider
  — sans quoi Terraform/OpenTofu refuserait la configuration (cycle de
  provider). `scaleway_cockpit_source` (utilisé par `ruler_uri`), lui, est
  bien dans ce module malgré tout : il ne dépend que du provider `scaleway`,
  donc aucun cycle ne se forme quand `provider "mimir" {}` référence sa
  sortie `metrics_source_url` — seule une ressource qui dépend elle-même de
  `mimir` poserait problème. `scaleway_cockpit_token`/`alert_manager` restent
  donc dans l'appelant uniquement parce qu'ils alimentent `alertmanager_uri`/
  `org_id`, pas par nécessité générale.
- **`predefined_alerts_usage`** (seuils, expressions patchées, activation
  par alerte préconfigurée Scaleway) est figé dans ce module, pas exposé en
  variable : c'est la logique qu'on veut identique sur tous les projets.
  Seul `custom_rules_groups` varie par projet.
- **`webhook_url_critical`/`_warning`/`_info`** sont des variables
  obligatoires et sensibles (`sensitive = true`) : ce module ne fixe plus
  aucune URL de webhook en interne. À passer via `TF_VAR_...` ou un backend
  de secrets — jamais en dur dans un fichier `.tfvars` versionné.
- `custom_rules_groups` est typé en `list(any)` (pas de `object({...})`
  strict) vu la forme imbriquée et partiellement optionnelle de `rules` (cf.
  `variables.tf`).
