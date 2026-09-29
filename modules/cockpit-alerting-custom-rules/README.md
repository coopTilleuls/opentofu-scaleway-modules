# cockpit-alerting-custom-rules

Crée un groupe de règles d'alerte Mimir (`mimir_rule_group_alerting`) pour
**une** ressource Scaleway donnée, à partir d'un jeu de règles prédéfini par
type (`type`), avec un niveau de service (`service_level`) qui pilote le
routage des alertes critical. À instancier une fois par ressource à surveiller
(une base PostgreSQL, une public gateway...), en complément du module
[`cockpit-alerting`](../cockpit-alerting) (>= 3.0.0) qui gère les sources
Cockpit, les alertes préconfigurées Scaleway et la configuration Alertmanager.

Ces règles étaient auparavant codées en dur dans `cockpit-alerting`
(`additionnal_rules_groups`) et appliquées en bloc à tous les projets.

| `type` | Règles (warning / critical) |
|---|---|
| `kubernetes` | ETCD disk quota, CPU API server (control plane Kapsule) |
| `s2s_vpn` | Bande passante entrante / sortante |
| `public_gateway` | Bande passante entrante / sortante (nécessite `public_gateway_size`) |
| `postgresql` | Mémoire RDB PostgreSQL |
| `opensearch` | CPU, mémoire, load average |

| `service_level` | Alertes critical |
|---|---|
| `24/7` | Toujours vers `webhook_url_critical` |
| `5/7` | Vers `webhook_url_critical` aux heures ouvrées (`business_hours` de `cockpit-alerting`, par défaut lun-ven 09:00-18:00 Europe/Paris), vers `webhook_url_warning` en dehors |

Les alertes warning ne dépendent pas du `service_level`.

## Exemple

```hcl
module "alerting_rules_db_app" {
  source = "git::https://<repo-url>//modules/cockpit-alerting-custom-rules?ref=cockpit-alerting-custom-rules-vX.Y.Z"

  type          = "postgresql"
  service_level = "24/7"
  resource_name = "app-db" # nom Scaleway de l'instance RDB
}

module "alerting_rules_public_gateway" {
  source = "git::https://<repo-url>//modules/cockpit-alerting-custom-rules?ref=cockpit-alerting-custom-rules-vX.Y.Z"

  type                = "public_gateway"
  service_level       = "5/7"
  resource_name       = "my-gateway"
  public_gateway_size = "M"
}

# Toutes les ressources du type, sans filtre
module "alerting_rules_kubernetes" {
  source = "git::https://<repo-url>//modules/cockpit-alerting-custom-rules?ref=cockpit-alerting-custom-rules-vX.Y.Z"

  type          = "kubernetes"
  service_level = "24/7"
}
```

Le provider `mimir` est celui déjà configuré par l'appelant pour
`cockpit-alerting` (cf. son README) : ce module n'en déclare pas.

## Remarques

- **`resource_name`** filtre chaque expression PromQL sur le label
  `resource_name` des métriques Cockpit. À `null`, le groupe couvre toutes les
  ressources du type : ne pas le combiner avec une autre instance du même
  `type` filtrée sur une ressource, sinon cette ressource aura des alertes en
  double.
- Le nom du groupe Mimir est `Custom Rules - <Type> - <resource_name|all>`
  (caractères non autorisés remplacés par `_`) : deux instances avec le même
  `type` et le même `resource_name` entrent en collision.
- Le routage `service_level` est porté par le module `cockpit-alerting`
  (routes Alertmanager sur le label `service_level`) : avec une version
  antérieure à 3.0.0, le label est posé mais sans effet.
- Seuils et durées sont figés dans le module, comme dans `cockpit-alerting`.
  Pour une règle vraiment spécifique à un projet, utiliser
  `custom_rules_groups` de `cockpit-alerting`.
