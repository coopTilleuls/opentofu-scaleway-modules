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
  description = <<-EOT
    Noms des permission sets Scaleway à accorder (ex: ["ObjectStorageFullAccess"]) via une
    `scaleway_iam_policy` dédiée. Laisser vide (défaut) si l'application n'a besoin d'aucune
    policy propre, par exemple lorsqu'elle est simplement rattachée à un groupe IAM existant via
    `iam_group_id`.
  EOT
  type        = list(string)
  default     = []
}

variable "iam_group_id" {
  description = <<-EOT
    ID d'un groupe IAM existant auquel rattacher l'application (motif observé pour la clé CI
    GitLab de sweeek : application membre du groupe "LeadDeveloper", sans policy dédiée). Laisser
    à null (défaut) pour ne pas rattacher l'application à un groupe.
  EOT
  type        = string
  default     = null
}

variable "default_project_id" {
  description = <<-EOT
    Projet Scaleway par défaut de la clé API générée (`default_project_id` sur
    `scaleway_iam_api_key`). Renseigné dans toutes les occurrences liées à l'Object Storage des
    deux repos d'origine (Velero, Loki, CNPG, buckets applicatifs) ; laisser à null (défaut) pour
    les autres usages (Container Registry, ESO, CI...) qui ne le renseignaient jamais.
  EOT
  type        = string
  default     = null
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
