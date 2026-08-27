variable "project_id" {
  description = "ID du projet Scaleway dont on récupère les alertes préconfigurées Cockpit."
  type        = string
}

variable "region" {
  description = "Région Scaleway. Laisser à null pour utiliser la région par défaut du provider."
  type        = string
  default     = null
}

variable "metrics_retention_days" {
  description = "Rétention (en jours) de la source Cockpit de métriques."
  type        = number
  default     = 6
}

variable "logs_retention_days" {
  description = "Rétention (en jours) de la source Cockpit de logs."
  type        = number
  default     = 30
}

variable "traces_retention_days" {
  description = "Rétention (en jours) de la source Cockpit de traces."
  type        = number
  default     = 15
}

variable "metrics_name" {
  description = <<-EOT
    Nom de la source Cockpit de métriques. `name` est `ForceNew` côté provider Scaleway : ne changer
    cette valeur que si vous acceptez un destroy+create de la source. Par défaut à `"metrics-source"`
    pour ne pas changer le comportement des appelants existants ; à surcharger avec le nom réel (ex.
    `"Scaleway Metrics"`) uniquement pour importer une source par défaut préexistante sans recréation.
  EOT
  type        = string
  default     = "metrics-source"
}

variable "logs_name" {
  description = "Nom de la source Cockpit de logs. Voir `metrics_name` pour la remarque ForceNew."
  type        = string
  default     = "logs-source"
}

variable "traces_name" {
  description = "Nom de la source Cockpit de traces. Voir `metrics_name` pour la remarque ForceNew."
  type        = string
  default     = "traces-source"
}

variable "is_production" {
  description = <<-EOT
    Détermine quel webhook reçoit les alertes critiques (`webhook_url_critical` si `true`,
    `webhook_url_warning` sinon). À passer explicitement par l'appelant (ex:
    `terraform.workspace == "prod"`) : ce module ne lit jamais `terraform.workspace` lui-même.
  EOT
  type        = bool
  default     = false
}

variable "webhook_url_critical" {
  description = <<-EOT
    URL du webhook Alertmanager appelé pour les alertes `severity=critical` (et, si
    `is_production = false`, utilisé à la place de `webhook_url_warning` pour la route par
    défaut de sévérité critique). Compatible avec n'importe quel système d'alerte exposant un
    endpoint webhook Alertmanager (Grafana OnCall, PagerDuty, Opsgenie, etc.). Sensible : ne pas
    committer de valeur en dur, à passer via une variable d'environnement `TF_VAR_...` ou un
    backend de secrets.
  EOT
  type        = string
  sensitive   = true
}

variable "webhook_url_warning" {
  description = "URL du webhook Alertmanager appelé pour les alertes `severity=warning`. Voir `webhook_url_critical` pour le format attendu et la remarque sur la sensibilité."
  type        = string
  sensitive   = true
}

variable "webhook_url_info" {
  description = "URL du webhook Alertmanager appelé par la route par défaut (alertes sans routage explicite warning/critical). Voir `webhook_url_critical` pour le format attendu et la remarque sur la sensibilité."
  type        = string
  sensitive   = true
}

variable "custom_rules_groups" {
  description = <<-EOT
    Groupes de règles d'alerte custom additionnels, fusionnés avec ceux dérivés automatiquement des
    alertes préconfigurées Scaleway (`data.scaleway_cockpit_preconfigured_alert` + la table interne
    `predefined_alerts_usage`). Chaque groupe : `{ name = string, rules = [...] }`, chaque règle :
    `{ name, threshold = { warning, critical }, duration = { warning, critical }, expression,
    comparaison, annotations = { summary, ... }, description, runbook_url }`. Type volontairement
    non contraint (`any`) vu la forme imbriquée de `rules`.
  EOT
  type        = list(any)
  default     = []
}

variable "public_gateway_size" {
  description = "Public gateway size (S/M/L/XL). used to monitor public gateway bandwidth usage until a metric gives the capacity"
  type        = string
}
