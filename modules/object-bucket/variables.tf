variable "name" {
  description = "Nom du bucket Object Storage."
  type        = string
}

variable "project_id" {
  description = "ID du projet Scaleway auquel rattacher le bucket. Laisser à null pour utiliser le projet par défaut du provider."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags appliqués au bucket, sous forme clé/valeur (contrairement aux autres ressources Scaleway, `scaleway_object_bucket` attend une map et non une liste)."
  type        = map(string)
  default     = {}
}

variable "versioning_enabled" {
  description = "Active le versioning du bucket. Attention : une fois activé, un bucket ne peut plus jamais repasser en non-versionné."
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = <<-EOT
    Règles de cycle de vie du bucket (expiration des objets / des versions non courantes).
    Couvre les usages observés dans les repos d'origine (rétention des sauvegardes Velero,
    expiration des sauvegardes CNPG) ; pas d'attributs de transition de storage class, non utilisés
    à ce jour.
  EOT
  type = list(object({
    id                                 = optional(string)
    enabled                            = optional(bool, true)
    prefix                             = optional(string)
    expiration_days                    = optional(number)
    noncurrent_version_expiration_days = optional(number)
  }))
  default = []
}

variable "sre_group_id" {
  description = <<-EOT
    ID du groupe IAM SRE auquel accorder un accès complet au bucket (statement "sre secure
    statement" des repos d'origine). Laisser à null pour ne pas ajouter ce statement.
  EOT
  type        = string
  default     = null
}

variable "sre_actions" {
  description = "Actions S3 accordées au groupe SRE."
  type        = list(string)
  default     = ["s3:*"]
}

variable "app_application_id" {
  description = <<-EOT
    ID de l'application IAM (ex: produite par le module `iam-app-identity`) à qui accorder un
    accès scopé au bucket. Laisser à null pour ne pas ajouter ce statement.
  EOT
  type        = string
  default     = null
}

variable "app_actions" {
  description = "Actions S3 accordées à l'application."
  type        = list(string)
  default     = ["s3:*"]
}

variable "additional_policy_statements" {
  description = <<-EOT
    Statements de policy IAM Scaleway supplémentaires, au format brut attendu par
    `scaleway_object_bucket_policy` (ex: le statement "lead developer" du repo `ffspt`). Permet de
    couvrir un besoin ponctuel sans complexifier l'interface de ce module.
  EOT
  type        = list(any)
  default     = []
}
