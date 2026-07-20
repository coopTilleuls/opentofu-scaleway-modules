# rdb-postgresql

Crée une instance de base de données managée Scaleway (PostgreSQL), avec ses
bases de données et, optionnellement, un utilisateur applicatif dédié par base
(mot de passe généré aléatoirement, privilège `all` scopé à cette base).

## Exemple

```hcl
module "postgresql" {
  source = "git::https://<repo-url>//modules/rdb-postgresql?ref=vX.Y.Z"

  name               = "myproject-rdb-${terraform.workspace}"
  project_id         = var.project_id
  node_type          = "db-dev-m"
  is_ha_cluster      = true
  volume_size_in_gb  = 25
  private_network_id = module.vpc.private_network_ids["tools"]
  tags               = ["myproject"]

  backup_schedule_retention = terraform.workspace == "nonprod" ? 1 : 7

  databases               = ["api", "wonderflow"]
  create_dedicated_users  = true
}
```

## Remarques

- `prevent_destroy = true` est figé en dur sur l'instance : la déprotéger nécessite d'éditer
  ce module. C'est volontaire, une base de données de production ne doit pas pouvoir être
  détruite par un `tofu apply`/`destroy` accidentel.
- Si `admin_password` n'est pas fourni, un mot de passe est généré et exposé (sensible) via
  l'output `admin_password`.
- `create_dedicated_users = false` reproduit le cas d'usage le plus simple (une seule base,
  connexion applicative avec l'utilisateur admin) ; `= true` (par défaut) reproduit le cas
  d'usage multi-bases avec un utilisateur applicatif isolé par base.
- `settings` permet le tuning fin du moteur (`effective_cache_size`, `max_connections`,
  `work_mem`...) — vérifier la documentation Scaleway du moteur pour les unités attendues
  (certains réglages sont en Mo et non en ko).
