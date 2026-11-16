variable "name" {
  description = "Nom du namespace de registry."
  type        = string
}

variable "description" {
  description = "Description du namespace."
  type        = string
  default     = null
}

variable "is_public" {
  description = "Si `true`, les images du namespace sont téléchargeables publiquement (`docker pull` sans authentification)."
  type        = bool
  default     = false
}

variable "project_id" {
  description = "ID du projet Scaleway auquel rattacher le namespace. Laisser à null pour utiliser le projet par défaut du provider."
  type        = string
  default     = null
}

variable "region" {
  description = "Région Scaleway du namespace. Laisser à null pour utiliser la région par défaut du provider."
  type        = string
  default     = null
}

variable "retention" {
  description = <<-EOT
    Purge planifiée des anciens tags (Serverless Job + application IAM dédiée). Laisser à null
    (défaut) pour ne rien créer. Pour chaque image dont le nom matche `image_regex`, chaque tag est
    rattaché à la première règle de `rules` dont `tag_regex` le matche (un tag qui ne matche aucune
    règle, ou qui matche `protected_tag_regex`, est conservé). Dans une règle, les `keep_last` tags
    les plus récents de l'image sont conservés, les suivants sont supprimés s'ils ont plus de
    `older_than_days` jours. Un tag partageant son digest avec un tag conservé n'est jamais
    supprimé. `empty_image_older_than_days` supprime en plus les images restées sans aucun tag.
    Commencer par `dry_run = true` et lire les logs du job.
  EOT
  type = object({
    rules = list(object({
      tag_regex       = string
      keep_last       = optional(number, 0)
      older_than_days = optional(number, 0)
    }))
    protected_tag_regex         = optional(string, "^latest$")
    image_regex                 = optional(string, ".*")
    empty_image_older_than_days = optional(number)
    schedule                    = optional(string, "0 3 * * *")
    timezone                    = optional(string, "Europe/Paris")
    dry_run                     = optional(bool, false)
    job_image                   = optional(string, "python:3.13-alpine")
  })
  default = null

  validation {
    condition     = var.retention == null || try(length(var.retention.rules) > 0, false)
    error_message = "retention.rules doit contenir au moins une règle."
  }

  validation {
    condition = var.retention == null || try(alltrue([
      for r in var.retention.rules : r.keep_last >= 0 && r.older_than_days >= 0 && (r.keep_last > 0 || r.older_than_days > 0)
    ]), false)
    error_message = "Chaque règle doit avoir keep_last >= 0 et older_than_days >= 0, avec au moins l'un des deux > 0 (sinon elle supprimerait tous les tags qu'elle cible)."
  }

  validation {
    condition     = var.retention == null || try(var.retention.empty_image_older_than_days == null || var.retention.empty_image_older_than_days >= 0, false)
    error_message = "retention.empty_image_older_than_days doit être >= 0 (ou null pour désactiver)."
  }
}
