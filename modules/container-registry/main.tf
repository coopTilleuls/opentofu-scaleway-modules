# Ce module se limite volontairement à la création du namespace de registry : la clé de pull
# (application IAM + policy ContainerRegistryReadOnly) est déléguée au module `iam-app-identity`,
# pour éviter de dupliquer la logique IAM déjà couverte par ce dernier (cf. README).
resource "scaleway_registry_namespace" "this" {
  name        = var.name
  description = var.description
  is_public   = var.is_public
  project_id  = var.project_id
  region      = var.region
}
