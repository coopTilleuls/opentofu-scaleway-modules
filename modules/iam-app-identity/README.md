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

  # Renseigné dans toutes les occurrences liées à l'Object Storage des deux repos d'origine
  # (Velero, Loki, CNPG, buckets applicatifs) : projet par défaut de la clé API générée.
  default_project_id = var.project_id

  create_secret = true
}
```

Autre motif observé (clé CI GitLab de sweeek) : une application simplement rattachée à un groupe
IAM existant, sans policy dédiée — laisser `permission_set_names` vide et renseigner
`iam_group_id` :

```hcl
module "gitlab_ci_identity" {
  source = "git::https://<repo-url>//modules/iam-app-identity?ref=iam-app-identity-vX.Y.Z"

  name         = "gitlab-ci"
  iam_group_id = data.scaleway_iam_group.lead_developer.id
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
- `permission_set_names` vide (défaut) ne crée aucune `scaleway_iam_policy` : c'est le cas du
  motif "rattachement à un groupe IAM existant" (`iam_group_id`), pour éviter une policy redondante
  avec les droits déjà accordés par le groupe.
- `create_secret = true` stocke les identifiants dans Secret Manager (utile par exemple pour une
  synchronisation vers Kubernetes via External Secrets Operator). Le contenu par défaut du secret
  est `{"access_key": "...", "secret_key": "..."}` — **ce format ne reproduit aucune des
  occurrences observées dans les deux repos d'origine** (elles utilisent `AWS_ACCESS_KEY_ID`/
  `AWS_SECRET_ACCESS_KEY`, ou `access-key`/`secret-access-key` pour le bootstrap ESO) : fournir
  `secret_data` pour reproduire le format attendu par le consommateur réel.
- `default_project_id` (clé API) : à renseigner pour les usages Object Storage (Velero, Loki,
  CNPG, buckets applicatifs) ; laisser à `null` pour les autres (Container Registry, ESO, CI...).
