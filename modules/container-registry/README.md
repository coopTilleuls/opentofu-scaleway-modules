# container-registry

Crée un namespace Container Registry Scaleway. Se compose avec le module
[`iam-app-identity`](../iam-app-identity) pour le pull-secret utilisé par le
cluster Kubernetes (motif observé à l'identique dans les deux repos audités :
une application IAM dédiée avec la permission `ContainerRegistryReadOnly`).

## Exemple

```hcl
module "registry" {
  source = "git::https://<repo-url>//modules/container-registry?ref=container-registry-vX.Y.Z"

  name       = "myproject-cr"
  project_id = var.project_id
}

module "registry_pull_secret" {
  source = "git::https://<repo-url>//modules/iam-app-identity?ref=iam-app-identity-vX.Y.Z"

  name                 = "kubernetes-imagepullsecret"
  permission_set_names = ["ContainerRegistryReadOnly"]
  project_ids          = [var.project_id]
}
```

## Remarques

- Ce module ne crée volontairement pas la clé de pull lui-même : la logique IAM (application +
  clé API + policy) est déjà couverte par `iam-app-identity`, la dupliquer ici serait redondant.
