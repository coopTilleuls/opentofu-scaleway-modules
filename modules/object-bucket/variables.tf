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

variable "enable_sre_access" {
  description = <<-EOT
    Force explicitement la présence (`true`) ou l'absence (`false`) du statement SRE, indépendamment
    de la valeur de `sre_group_id`. Laisser à null (défaut) pour déduire automatiquement de
    `sre_group_id != null` — ce qui échoue avec "Invalid count argument" si `sre_group_id` provient
    d'une ressource créée dans ce même apply (sa valeur n'est alors pas encore connue au plan).
    Passer `true` explicitement dans ce cas.
  EOT
  type        = bool
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

variable "enable_app_access" {
  description = <<-EOT
    Équivalent de `enable_sre_access` pour `app_application_id`. À passer explicitement à `true`
    quand `app_application_id` référence une application IAM créée dans le même apply (cas le plus
    courant : ce module est presque toujours associé à `iam-app-identity` dans le même apply, voir
    l'exemple du README).
  EOT
  type        = bool
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
