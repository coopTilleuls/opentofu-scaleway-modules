# rdb-mysql

Crée une instance de base de données managée Scaleway (MySQL), avec ses bases
de données et, optionnellement, un utilisateur applicatif dédié par base (mot
de passe généré aléatoirement, privilège `all` scopé à cette base).

Structure quasiment jumelle du module [`rdb-postgresql`](../rdb-postgresql) —
seuls le moteur, l'utilisateur admin par défaut (`root`) et l'absence de
tuning fin par défaut diffèrent.

## Exemple

```hcl
module "mysql" {
  source = "git::https://<repo-url>//modules/rdb-mysql?ref=vX.Y.Z"

  name               = "mysql-api-${terraform.workspace}"
  project_id         = var.project_id
  is_ha_cluster      = terraform.workspace == "prod"
  volume_size_in_gb  = 10
  private_network_id = module.vpc.private_network_ids["tools"]
  tags               = ["myproject"]

  databases = ["blog"]
}
```

## Remarques

- `prevent_destroy = true` est figé en dur sur l'instance : la déprotéger nécessite d'éditer
  ce module.
- Si `admin_password` n'est pas fourni, un mot de passe est généré et exposé (sensible) via
  l'output `admin_password`.
- Aucun des deux repos d'origine n'utilisait de tuning `settings` pour MySQL ; le paramètre
  reste disponible pour un usage futur mais vide par défaut.
