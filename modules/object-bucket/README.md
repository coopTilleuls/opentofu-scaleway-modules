# object-bucket

Crée un bucket Object Storage Scaleway avec sa policy : un statement d'accès
complet pour un groupe IAM "SRE" et/ou un statement d'accès scopé pour une
application IAM (typiquement produite par le module
[`iam-app-identity`](../iam-app-identity)). Motif répété à l'identique pour
Velero, Loki, CNPG et les buckets applicatifs dans les deux repos audités.

## Exemple

```hcl
module "velero_identity" {
  source = "git::https://<repo-url>//modules/iam-app-identity?ref=vX.Y.Z"

  name                 = "velero"
  permission_set_names = ["ObjectStorageFullAccess"]
  project_ids          = [var.project_id]
}

module "velero_bucket" {
  source = "git::https://<repo-url>//modules/object-bucket?ref=vX.Y.Z"

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
}
```

## Remarques

- `tags` attend une **map** clé/valeur (`{ project = "myproject" }`), contrairement à la plupart
  des autres ressources Scaleway qui attendent une liste de chaînes — c'est une particularité de
  `scaleway_object_bucket` (tags de type S3).
- Si ni `sre_group_id`, ni `app_application_id`, ni `additional_policy_statements` ne sont
  renseignés, aucune `scaleway_object_bucket_policy` n'est créée (bucket sans policy explicite).
- Le format `Principal.SCW = "group_id:<id>"` pour les groupes est déduit par analogie avec les
  formats documentés par Scaleway pour `user_id:`/`application_id:`/`project_id:` — à vérifier au
  premier `tofu apply` si Scaleway venait à changer ce format.
- `additional_policy_statements` permet d'ajouter un statement ad hoc (ex: le statement "lead
  developer" observé dans `ffspt/.../dump.tf`) sans complexifier l'interface du module.
