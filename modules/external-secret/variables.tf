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

variable "bootstrap_secret_name" {
  description = <<-EOT
    Nom du secret Secret Manager contenant les credentials (`access-key`/`secret-access-key`) du
    compte de service utilisés par le `SecretStore` pour s'authentifier. Scaleway ne supportant pas
    l'authentification sans credentials explicites (contrairement à AWS/IRSA), ce secret doit être
    créé manuellement au préalable dans la console Scaleway (voir README) : ce module ne le crée
    pas, il le lit et le recopie en secret Kubernetes dans chaque namespace.
  EOT
  type        = string
  default     = "scwsm-secret"
}

variable "secret_store_name" {
  description = "Nom du `SecretStore` créé dans chaque namespace."
  type        = string
  default     = "secretstore"
}

variable "external_secret_name" {
  description = "Nom de l'`ExternalSecret` créé dans chaque namespace."
  type        = string
  default     = "app"
}

variable "target_secret_name" {
  description = "Nom du secret Kubernetes créé par l'`ExternalSecret` (`spec.target.name`) dans chaque namespace."
  type        = string
  default     = "external-secrets"
}

variable "refresh_interval" {
  description = "Intervalle de resynchronisation de l'`ExternalSecret` avec le Secret Manager."
  type        = string
  default     = "5m"
}
