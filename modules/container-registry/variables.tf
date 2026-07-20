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
