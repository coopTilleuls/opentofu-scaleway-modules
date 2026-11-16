# cockpit-alerting-logs-rules

Crée un groupe de règles d'alerte **Loki** (LogQL, `loki_rule_group_alerting`) dans le ruler de
la source de logs Cockpit, pour **une** ressource dont les logs sont poussés par Grafana Alloy
avec un label `host`. Pendant LogQL du module [`cockpit-alerting-custom-rules`](../cockpit-alerting-custom-rules)
(PromQL / Mimir). Les alertes sont routées par l'Alertmanager Cockpit configuré par
[`cockpit-alerting`](../cockpit-alerting), selon le label `severity`.

Module séparé de `cockpit-alerting` pour ne pas imposer un provider `loki` (et un token
supplémentaire) à tous ses appelants.

| `type` | Alertes |
|---|---|
| `bastion` | `ManualPgDump`, `SensitiveConfigChange`, `SshAuthFailures`, `LogsAbsent` |

### `bastion`

Pour un bastion (module [`bastion`](../bastion)) avec auditd et Grafana Alloy déployés par ansible
(labels `host`, `source="journald"` + `unit`, `source="auditd"`) — voir aussi le dashboard
`bastion` du module `cockpit-alerting`.

| Alerte | Déclenchement |
|---|---|
| `ManualPgDump` | `pg_dump` (clé auditd `pg_extract`) lancé par un humain : AUID ni `root` (cron, via `pam_loginuid`) ni `unset` |
| `SensitiveConfigChange` | écriture sur sudoers, sshd_config, passwd/shadow/group ou `/etc/audit` (clés `sudoers`, `sshd`, `identity`, `audit_config`) dans une session (AUID ≠ `unset`) — se déclenche aussi lors d'un déploiement ansible qui modifie ces fichiers (utilisateur `admin`) |
| `SshAuthFailures` | plus de `ssh_auth_failures_threshold` (20) échecs d'authentification SSH en 10 min |
| `LogsAbsent` | aucun heartbeat (`syslog_identifier="alloy-heartbeat"`) depuis `logs_absent_duration` (15m) : bastion, Alloy ou timer heartbeat arrêté, token invalide |

Prérequis côté bastion :

- un heartbeat journald plus fréquent que `logs_absent_duration`, avec l'identifiant
  `alloy-heartbeat`, et Alloy qui pose le label `syslog_identifier` (relabel de
  `__journal_syslog_identifier`). journald seul ne suffit pas : il peut rester silencieux plus
  d'une heure sur un bastion au repos (faux positifs). Exemple de timer systemd toutes les 5 min :
  `ExecStart=/usr/bin/logger -t alloy-heartbeat alive` + `OnUnitActiveSec=5min` ;
- auditd en `log_format = ENRICHED` (défaut Debian), qui ajoute le nom d'utilisateur
  `AUID="..."` utilisé par `ManualPgDump` et `SensitiveConfigChange`, et clés auditd identiques à
  celles ci-dessus.

Les labels `user` et `key` (extraits des logs) sont présents sur les alertes et utilisés dans les
annotations ; chaque utilisateur / clé donne une alerte distincte.

## Exemple

```hcl
# Token dédié aux règles Loki : modifier les scopes du token utilisé par le provider mimir
# forcerait son remplacement (et changerait l'org_id du provider dans le même apply).
resource "scaleway_cockpit_token" "logs_rules" {
  project_id = var.project_id
  name       = "terraform_logs_rules_${terraform.workspace}"
  scopes {
    setup_logs_rules = true
    write_metrics    = false
    write_logs       = false
  }
}

provider "loki" {
  uri    = module.cockpit_alerting.logs_source_url
  org_id = scaleway_cockpit_token.logs_rules.secret_key
}

module "alerting_logs_rules_bastion" {
  source = "git::https://<repo-url>//modules/cockpit-alerting-logs-rules?ref=cockpit-alerting-logs-rules-vX.Y.Z"

  type = "bastion"
  host = "bastion-${terraform.workspace}" # label host posé par Alloy

  # optionnel, valeurs par défaut ci-dessous
  severity                    = "warning"
  ssh_auth_failures_threshold = 20
  logs_absent_duration        = "15m"
  namespace                   = "terraform"
  labels                      = {}
}
```

## Remarques

- Le provider `fgouteroux/loki` est épinglé en `= 0.0.6` (provider non officiel, même logique
  que `fgouteroux/mimir` dans `cockpit-alerting`).
- L'authentification sur le ruler Cockpit reprend celle du provider mimir de `cockpit-alerting`
  (`org_id` = secret du token Cockpit).
- Pour ajouter un type : une entrée dans `local.rules_groups` (`main.tf`) et dans la validation
  de `var.type`. Les expressions sont du LogQL : les tester dans Grafana Cockpit (Explore, source
  de logs) avant de les committer.
