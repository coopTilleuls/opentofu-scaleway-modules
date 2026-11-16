variable "type" {
  description = <<-EOT
    Type de ressource surveillée, qui détermine le jeu de règles LogQL créé :
    `bastion` (sshd via journald, auditd, heartbeat Alloy).
  EOT
  type        = string

  validation {
    condition     = contains(["bastion"], var.type)
    error_message = "type doit valoir bastion."
  }
}

variable "host" {
  description = "Valeur du label Loki `host` posé par Grafana Alloy sur les logs de la ressource (ex. `bastion-prod`). Les expressions sont filtrées sur ce label."
  type        = string
}

variable "namespace" {
  description = "Namespace du ruler Loki Cockpit dans lequel créer le groupe de règles."
  type        = string
  default     = "terraform"
}

variable "ssh_auth_failures_threshold" {
  description = "(`bastion`) Nombre d'échecs d'authentification SSH sur 10 minutes au-delà duquel l'alerte `SshAuthFailures` se déclenche."
  type        = number
  default     = 20
}

variable "logs_absent_duration" {
  description = "(`bastion`) Durée sans heartbeat journald (`syslog_identifier=\"alloy-heartbeat\"`) avant de déclencher l'alerte `LogsAbsent` (bastion arrêté, Alloy KO, token Cockpit invalide...). Doit dépasser nettement la période du heartbeat."
  type        = string
  default     = "15m"
}

variable "severity" {
  description = "Sévérité (label `severity`) posée sur toutes les alertes, routée par l'Alertmanager configuré par le module `cockpit-alerting`."
  type        = string
  default     = "warning"

  validation {
    condition     = contains(["info", "warning", "critical"], var.severity)
    error_message = "severity doit valoir info, warning ou critical."
  }
}

variable "labels" {
  description = "Labels additionnels posés sur chaque alerte (ex. `{ team = \"sre\" }`). `severity` est réservé et écrasé par le module."
  type        = map(string)
  default     = {}
}
