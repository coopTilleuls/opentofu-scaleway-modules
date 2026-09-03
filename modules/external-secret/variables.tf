variable "name" {
  description = "Nom de l'application IAM créée pour la lecture du Secret Manager (ex: \"secret-manager-$${terraform.workspace}\")."
  type        = string
}

variable "project_id" {
  description = "ID du projet Scaleway sur lequel porte la policy IAM et dans lequel se trouve le Secret Manager."
  type        = string
}

variable "region" {
  description = "Région Scaleway du Secret Manager, référencée dans le provider `scaleway` du `SecretStore`."
  type        = string
  default     = "fr-par"
}

variable "namespaces" {
  description = <<-EOT
    Namespaces Kubernetes pour lesquels créer un secret Secret Manager, un `SecretStore` et un
    `ExternalSecret`. Chaque namespace doit déjà exister (ce module n'en gère pas la création, cf
    périmètre "pas de ressource Kubernetes applicative" du repo).
  EOT
  type        = set(string)
}

variable "allowed_secrets_ids" {
  description = <<-EOT
    Liste des ids des scaleway_secrets sur lesquels autoriser les accès. peut-être dispo uniquement à partir du moment ou il y a au moins une version.
  EOT
  type        = set(string)
}
