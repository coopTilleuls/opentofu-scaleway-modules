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

variable "prevent_destroy" {
  description = <<-EOT
    Protège le bucket contre une destruction via `tofu apply`/`destroy` accidentel. `false` par
    défaut pour ne pas changer le comportement des consommateurs existants de ce module. `lifecycle.
    prevent_destroy` doit être une constante littérale (impossible de référencer une variable) :
    ce module crée donc en interne deux ressources `scaleway_object_bucket` mutuellement
    exclusives (`count`), une par valeur de ce booléen — transparent pour l'appelant, qui ne voit
    que les outputs `bucket_*`.
  EOT
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

variable "readwrite_group_ids" {
  description = <<-EOT
    ID des groupe IAM auxquels accorder un accès complet au bucket
  EOT
  type        = list(string)
  default     = []
}

variable "readwrite_actions" {
  description = "Actions S3 accordées aux groupes de readwrite_group_ids"
  type        = list(string)
  default     = ["s3:*"]
}

variable "readonly_group_ids" {
  description = <<-EOT
    ID des groupe IAM auxquels accorder un accès complet au bucket
  EOT
  type        = list(string)
  default     = []
}

variable "readonly_actions" {
  description = "Actions S3 accordées aux groupes de readonly_group_ids"
  type        = list(string)
  default     = [
    "s3:GetBucketAcl",
    "s3:GetBucketCORS",
    "s3:GetBucketLocation",
    "s3:GetBucketObjectLockConfiguration",
    "s3:GetBucketTagging",
    "s3:GetBucketVersioning",
    "s3:GetBucketWebsite",
    "s3:GetEncryptionConfiguration",
    "s3:GetLifecycleConfiguration",
    "s3:ListBucket",
    "s3:ListBucketMultipartUploads",
    "s3:ListBucketVersions",
  ]
}


variable "application_ids" {
  description = <<-EOT
    IDs des application IAM (ex: produite par le module `iam-app-identity`) à qui accorder un
    accès scopé au bucket. Laisser à null pour ne pas ajouter ce statement.
  EOT
  type        = list(string)
  default     = []
}

variable "app_actions" {
  description = "Actions S3 accordées aux applications de application_ids"
  type        = list(string)
  default     = ["s3:*"]
}

variable "additional_policy_statements" {
  description = <<-EOT
    Statements de policy IAM Scaleway supplémentaires, au format brut attendu par
    `scaleway_object_bucket_policy` (ex: le statement "lead developer"). Permet de
    couvrir un besoin ponctuel sans complexifier l'interface de ce module.
  EOT
  type        = list(any)
  default     = []
}
