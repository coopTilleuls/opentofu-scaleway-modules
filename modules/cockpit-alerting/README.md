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

  # optionnel, valeurs par défaut ci-dessous : heures ouvrées pour service_level = "5/7"
  business_hours = {
    start_time = "09:00"
    end_time   = "18:00"
    location   = "Europe/Paris"
  }

  # optionnel : règles vraiment spécifiques au projet. Pour les règles standard par type de
  # ressource (PostgreSQL, public gateway, ETCD...), utiliser cockpit-alerting-custom-rules.
  custom_rules_groups = [
    {
      name = "Custom - MyApp"
      rules = [
        {
          name        = "Queue backlog"
          threshold   = { warning = 1000, critical = 5000 }
          duration    = { warning = "10m", critical = "10m" }
          expression  = "sum(myapp_queue_messages)"
          comparaison = ">"
          annotations = { summary = "MyApp queue backlog is high." }
          description = "MyApp queue backlog is superior to THRESHOLD since DURATION"
          runbook_url = "https://wiki-sre.les-tilleuls.solutions/..."
        },
      ]
    }
  ]
}

# Une instance par ressource à surveiller, cf. modules/cockpit-alerting-custom-rules
module "alerting_rules_db_app" {
  source = "git::https://<repo-url>//modules/cockpit-alerting-custom-rules?ref=cockpit-alerting-custom-rules-vX.Y.Z"

  type          = "postgresql"
  service_level = "5/7"
  resource_name = "app-db"
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
- **Routage `service_level`** : les alertes `severity=critical` portant le
  label `service_level="5/7"` (posé par
  [`cockpit-alerting-custom-rules`](../cockpit-alerting-custom-rules)) ne
  partent vers `webhook_url_critical` qu'aux heures ouvrées
  (`business_hours`, lundi-vendredi, jours fériés non gérés), et vers
  `webhook_url_warning` le reste du temps. Toute autre alerte critical
  (`24/7`, alertes préconfigurées, `custom_rules_groups`) part toujours vers
  `webhook_url_critical`.
- **`webhook_url_critical`/`_warning`/`_info`** sont des variables
  obligatoires et sensibles (`sensitive = true`) : ce module ne fixe plus
  aucune URL de webhook en interne. À passer via `TF_VAR_...` ou un backend
  de secrets — jamais en dur dans un fichier `.tfvars` versionné.
- `custom_rules_groups` est typé en `list(any)` (pas de `object({...})`
  strict) vu la forme imbriquée et partiellement optionnelle de `rules` (cf.
  `variables.tf`).

## Migration 2.x → 3.0.0

- Les règles custom codées en dur (`additionnal_rules_groups` : ETCD, S2S VPN,
  Public Gateway, PostgreSQL, OpenSearch) ne sont plus créées par ce module :
  elles sont déplacées dans
  [`cockpit-alerting-custom-rules`](../cockpit-alerting-custom-rules), une
  instance par ressource. Ajouter les instances voulues dans le même apply que
  la montée de version, sinon ces alertes disparaissent. Les groupes Mimir
  sont supprimés puis recréés sous un nouveau nom
  (`Custom Rules - <Type> - <resource_name|all>`), sans collision avec les
  anciens.
- La variable `public_gateway_size` est supprimée (à passer désormais à
  l'instance `cockpit-alerting-custom-rules` de `type = "public_gateway"`).
