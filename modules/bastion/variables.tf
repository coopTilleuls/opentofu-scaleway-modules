variable "name" {
  description = "Nom de l'instance bastion."
  type        = string
}

variable "project_id" {
  description = "ID du projet Scaleway auquel rattacher le bastion. Laisser à null pour utiliser le projet par défaut du provider."
  type        = string
  default     = null
}

variable "zone" {
  description = "Zone Scaleway du bastion. Laisser à null pour utiliser la zone par défaut du provider."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Type d'instance compute du bastion."
  type        = string
  default     = "DEV1-S"
}

variable "image" {
  description = "UUID ou label de l'image utilisée par le bastion (ex: \"ubuntu_noble\", \"debian_trixie\"). Diffère selon les repos d'origine, donc pas de valeur par défaut."
  type        = string
}

variable "private_network_id" {
  description = "ID du private network sur lequel rattacher le bastion (généralement le private network \"tools\" produit par le module `vpc`)."
  type        = string
}

variable "additional_volume_size_gb" {
  description = "Taille (en Go) d'un volume additionnel à attacher au bastion. `0` pour ne pas en créer."
  type        = number
  default     = 0
}

variable "additional_volume_iops" {
  description = "IOPS du volume additionnel, si créé."
  type        = number
  default     = 5000
}

variable "user_data" {
  description = <<-EOT
    Données utilisateur de l'instance (map). La clé \"cloud-init\" est interprétée par Scaleway
    comme la configuration cloud-init de démarrage.
  EOT
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags appliqués au bastion."
  type        = list(string)
  default     = []
}
