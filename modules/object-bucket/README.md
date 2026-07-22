# object-bucket

Crée un bucket Object Storage Scaleway avec sa policy : un statement d'accès
complet pour un groupe IAM "SRE" et/ou un statement d'accès scopé pour une
application IAM (typiquement produite par le module
[`iam-app-identity`](../iam-app-identity)). Motif répété à l'identique pour
Velero, Loki, CNPG et les buckets applicatifs dans les deux repos audités.

## Exemple

```hcl
module "velero_identity" {
  source = "git::https://<repo-url>//modules/iam-app-identity?ref=iam-app-identity-vX.Y.Z"

  name                 = "velero"
  permission_set_names = ["ObjectStorageFullAccess"]
  project_ids          = [var.project_id]
}

module "velero_bucket" {
  source = "git::https://<repo-url>//modules/object-bucket?ref=object-bucket-vX.Y.Z"

  name       = "velero-${terraform.workspace}"
  project_id = var.project_id
  tags       = { project = "myproject", component = "velero" }

  versioning_enabled = true

  lifecycle_rules = [
    {
      id               = "backups-retention"
      prefix           = "backups/"
      expiration_days  = terraform.workspace == "prod" ? 30 : 7
    }
  ]

  sre_group_id        = data.scaleway_iam_group.sre.id
  app_application_id  = module.velero_identity.application_id
  # module.velero_identity est créé dans ce même apply : sa valeur n'est pas encore connue au
  # plan, donc à passer explicitement plutôt que de laisser ce module la déduire (voir remarque).
  enable_app_access   = true
}
```

## Remarques

- `tags` attend une **map** clé/valeur (`{ project = "myproject" }`), contrairement à la plupart
  des autres ressources Scaleway qui attendent une liste de chaînes — c'est une particularité de
  `scaleway_object_bucket` (tags de type S3).
- Si ni `sre_group_id`, ni `app_application_id`, ni `additional_policy_statements` ne sont
  renseignés, aucune `scaleway_object_bucket_policy` n'est créée (bucket sans policy explicite).
- **`enable_app_access`/`enable_sre_access`** : par défaut (`null`), la présence du statement
  correspondant est déduite de `xxx_id != null`. Cette déduction échoue avec `Invalid count
  argument` si `xxx_id` référence une ressource créée dans ce même apply (son ID n'est pas encore
  connu au moment du plan) — typiquement `app_application_id = module.xxx_identity.application_id`
  quand `iam-app-identity` est appelé dans le même apply, l'usage le plus courant de ce module.
  Passer `enable_app_access = true` (littéral, donc toujours connu) contourne le problème.
- `sre_group_id` résout le groupe via `data.scaleway_iam_group` et construit `Principal.SCW`
  comme une **liste de `user_id:<id>`** (un par membre du groupe), pas `"group_id:<id>"` : les deux
  repos d'origine évitent systématiquement ce dernier format (jamais éprouvé en production d'après
  leurs propres commentaires), et résolvent toujours le groupe en membres individuels.
- `additional_policy_statements` permet d'ajouter un statement ad hoc (ex: le statement "lead
  developer" observé dans `ffspt/.../dump.tf`) sans complexifier l'interface du module.
