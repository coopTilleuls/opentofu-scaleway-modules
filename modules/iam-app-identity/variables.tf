variable "name" {
  description = "Nom de l'application IAM (ex: \"velero\", \"loki\", \"external-secret\")."
  type        = string
}

variable "description" {
  description = "Description de l'application IAM."
  type        = string
  default     = null
}

variable "permission_set_names" {
  description = "Noms des permission sets Scaleway à accorder (ex: [\"ObjectStorageFullAccess\"])."
  type        = list(string)
}

variable "project_ids" {
  description = <<-EOT
    IDs des projets Scaleway sur lesquels s'applique la policy. Prioritaire sur `organization_id`
    si les deux sont renseignés. Un `rule` IAM Scaleway doit porter soit sur des projets, soit sur
    l'organisation entière.
  EOT
  type        = list(string)
  default     = []
}

variable "organization_id" {
  description = "ID de l'organisation Scaleway sur laquelle s'applique la policy, si `project_ids` n'est pas renseigné."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags appliqués à l'application et à la policy IAM."
  type        = list(string)
  default     = []
}

variable "create_secret" {
  description = <<-EOT
    Si `true`, stocke les identifiants (access_key/secret_key) générés dans Scaleway Secret
    Manager, pour être synchronisés vers Kubernetes via un External Secrets Operator par exemple.
  EOT
  type        = bool
  default     = false
}

variable "secret_name" {
  description = "Nom du secret créé dans Secret Manager. Laisser à null pour utiliser \"<name>-credentials\"."
  type        = string
  default     = null
}

variable "secret_project_id" {
  description = "ID du projet Scaleway du secret. Laisser à null pour utiliser le projet par défaut du provider."
  type        = string
  default     = null
}

variable "secret_data" {
  description = <<-EOT
    Contenu JSON du secret. Laisser à null pour générer automatiquement
    `{"access_key": "...", "secret_key": "..."}` à partir de la clé API créée par ce module.
  EOT
  type        = string
  default     = null
  sensitive   = true
}
