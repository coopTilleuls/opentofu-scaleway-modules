# iam-app-identity

Crée une identité applicative Scaleway complète : `iam_application` +
`iam_api_key` + `iam_policy`, et optionnellement le stockage des identifiants
dans Secret Manager. Motif répété à l'identique dans les deux repos audités
pour Velero, Loki, External Secrets Operator, CNPG, les buckets applicatifs,
le pull-secret du Container Registry, la clé CI GitLab...

## Exemple

```hcl
module "velero_identity" {
  source = "git::https://<repo-url>//modules/iam-app-identity?ref=iam-app-identity-vX.Y.Z"

  name                  = "velero"
  permission_set_names  = ["ObjectStorageFullAccess"]
  project_ids           = [var.project_id]
  tags                  = ["myproject", "velero"]

  create_secret = true
}
```

Le résultat (`access_key`/`secret_key`) se combine naturellement avec le module
[`object-bucket`](../object-bucket) :

```hcl
module "velero_bucket" {
  source = "git::https://<repo-url>//modules/object-bucket?ref=object-bucket-vX.Y.Z"

  name              = "velero-${terraform.workspace}"
  project_id        = var.project_id
  app_application_id = module.velero_identity.application_id
}
```

## Remarques

- `project_ids` prend le pas sur `organization_id` si les deux sont renseignés : une `rule` IAM
  Scaleway ne peut porter que sur l'un ou l'autre.
- `create_secret = true` reproduit le motif "credentials synchronisés vers Kubernetes via External
  Secrets Operator" observé dans les deux repos. Le contenu par défaut du secret est
  `{"access_key": "...", "secret_key": "..."}` ; fournir `secret_data` pour un format différent.
