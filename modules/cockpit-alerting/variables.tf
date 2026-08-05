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
    Détermine l'escalade par défaut de la route d'alerte (`oncall_24_7` si `true`, `oncall_7_5`
    sinon). À passer explicitement par l'appelant (ex: `terraform.workspace == "prod"`) : ce module
    ne lit jamais `terraform.workspace` lui-même.
  EOT
  type        = bool
  default     = false
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
