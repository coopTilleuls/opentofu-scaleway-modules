locals {
  # Sélecteurs LogQL des flux poussés par Grafana Alloy (cf. rôle ansible alloy du repo appelant).
  journald = "{host=\"${var.host}\", source=\"journald\"}"
  sshd     = "{host=\"${var.host}\", unit=\"ssh.service\"}"
  auditd   = "{host=\"${var.host}\", source=\"auditd\"}"

  # Utilisateur de connexion d'origine (AUID, conservé après sudo/su), ajouté par auditd en
  # log_format = ENRICHED (défaut Debian). On écarte :
  # - `unset` : processus hors session (démons, unattended-upgrades...) ;
  # - `root`  : cron (pam_loginuid fixe l'AUID au propriétaire du job, ex. l'export pg_dump planifié).
  auid_human = "| regexp `AUID=\"(?P<user>[^\"]+)\"` | user !~ `root|unset`"

  rules_groups = {
    bastion = {
      name = "Bastion"
      rules = [
        {
          alert = "ManualPgDump"
          expr  = "sum by (user) (count_over_time(${local.auditd} |= `key=\"pg_extract\"` ${local.auid_human} [5m])) > 0"
          for   = "0m"
          annotations = {
            summary     = "pg_dump lancé à la main sur ${var.host} par {{ $labels.user }}"
            description = "{{ $labels.user }} a exécuté pg_dump sur ${var.host} (clé auditd pg_extract), hors cron d'export. Détail : ausearch -k pg_extract -i --input-logs"
          }
        },
        {
          alert = "SensitiveConfigChange"
          expr  = "sum by (user, key) (count_over_time(${local.auditd} |~ `key=\"(sudoers|sshd|identity|audit_config)\"` | regexp `key=\"(?P<key>[^\"]+)\"` | regexp `AUID=\"(?P<user>[^\"]+)\"` | user != `unset` [5m])) > 0"
          for   = "0m"
          annotations = {
            summary     = "Configuration sensible modifiée sur ${var.host} ({{ $labels.key }}) par {{ $labels.user }}"
            description = "Écriture sur une configuration sensible (clé auditd {{ $labels.key }} : sudoers, sshd_config, passwd/shadow/group ou /etc/audit) par {{ $labels.user }} sur ${var.host}. Attendu lors d'un déploiement ansible (utilisateur admin). Détail : ausearch -k {{ $labels.key }} -i --input-logs"
          }
        },
        {
          alert = "SshAuthFailures"
          expr  = "sum(count_over_time(${local.sshd} |~ `Failed \\S+ for|Invalid user|authentication failure` [10m])) > ${var.ssh_auth_failures_threshold}"
          for   = "0m"
          annotations = {
            summary     = "Échecs d'authentification SSH en série sur ${var.host}"
            description = "{{ $value }} échecs d'authentification SSH en 10 minutes sur ${var.host} (seuil ${var.ssh_auth_failures_threshold}). Le port SSH n'est ouvert qu'aux IP autorisées : vérifier l'origine. Détail : journalctl -u ssh"
          }
        },
        {
          alert = "LogsAbsent"
          expr  = "absent_over_time(${local.journald} [${var.logs_absent_duration}])"
          for   = "0m"
          annotations = {
            summary     = "Plus aucun log de ${var.host} depuis ${var.logs_absent_duration}"
            description = "Aucun log journald reçu de ${var.host} depuis ${var.logs_absent_duration} : bastion arrêté, Grafana Alloy arrêté (systemctl status alloy) ou token Cockpit invalide."
          }
        },
      ]
    }
  }

  group = local.rules_groups[var.type]
}

resource "loki_rule_group_alerting" "this" {
  name      = replace("${local.group.name} - ${var.host}", "/[^a-zA-Z0-9-_.]/", "_")
  namespace = var.namespace

  dynamic "rule" {
    for_each = local.group.rules
    content {
      alert = replace("${local.group.name} - ${rule.value.alert}", "/[^a-zA-Z0-9-_.]/", "_")
      expr  = rule.value.expr
      for   = rule.value.for

      labels = merge(
        var.labels,
        {
          severity = var.severity
          host     = var.host
        }
      )
      annotations = merge(
        rule.value.annotations,
        {
          terraformed = "true"
        }
      )
    }
  }
}
