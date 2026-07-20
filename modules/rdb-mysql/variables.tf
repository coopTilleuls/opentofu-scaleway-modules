variable "name" {
  description = "Nom de l'instance RDB."
  type        = string
}

variable "project_id" {
  description = "ID du projet Scaleway auquel rattacher l'instance. Laisser à null pour utiliser le projet par défaut du provider."
  type        = string
  default     = null
}

variable "region" {
  description = "Région Scaleway de l'instance. Laisser à null pour utiliser la région par défaut du provider."
  type        = string
  default     = null
}

variable "engine_version" {
  description = "Version du moteur MySQL (ex: \"MySQL-8\")."
  type        = string
  default     = "MySQL-8"
}

variable "node_type" {
  description = "Type de nœud de l'instance (ex: \"db-dev-s\")."
  type        = string
  default     = "db-dev-s"
}

variable "is_ha_cluster" {
  description = "Active la haute disponibilité de l'instance."
  type        = bool
  default     = false
}

variable "admin_user_name" {
  description = "Nom du premier utilisateur (administrateur) de l'instance."
  type        = string
  default     = "root"
}

variable "admin_password" {
  description = "Mot de passe de l'utilisateur administrateur. Laisser à null pour en générer un aléatoirement (recommandé)."
  type        = string
  default     = null
  sensitive   = true
}

variable "volume_type" {
  description = "Type de volume (\"lssd\", \"sbs_5k\" ou \"sbs_15k\")."
  type        = string
  default     = "sbs_5k"
}

variable "volume_size_in_gb" {
  description = "Taille du volume en Go (ignoré si `volume_type = \"lssd\"`)."
  type        = number
  default     = 10
}

variable "encryption_at_rest" {
  description = "Active le chiffrement au repos."
  type        = bool
  default     = true
}

variable "disable_backup" {
  description = "Désactive les sauvegardes automatiques."
  type        = bool
  default     = false
}

variable "backup_schedule_frequency" {
  description = "Fréquence des sauvegardes automatiques, en heures."
  type        = number
  default     = 24
}

variable "backup_schedule_retention" {
  description = "Durée de rétention des sauvegardes automatiques, en jours."
  type        = number
  default     = 7
}

variable "backup_same_region" {
  description = "Stocke les sauvegardes logiques dans la même région que l'instance."
  type        = bool
  default     = false
}

variable "private_network_id" {
  description = "ID du private network sur lequel rattacher l'instance (généralement produit par le module `vpc`)."
  type        = string
}

variable "settings" {
  description = "Réglages fins du moteur MySQL. Vide par défaut : aucun des repos d'origine n'en utilisait pour MySQL."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags appliqués à l'instance."
  type        = list(string)
  default     = []
}

variable "databases" {
  description = "Noms des bases de données à créer sur l'instance."
  type        = list(string)
  default     = []
}

variable "create_dedicated_users" {
  description = <<-EOT
    Si `true`, crée pour chaque entrée de `databases` un utilisateur dédié du même nom (mot de
    passe généré aléatoirement) avec le privilège `all` sur cette base. Si `false`, seules les
    bases sont créées et la connexion applicative se fait avec l'utilisateur administrateur.
  EOT
  type        = bool
  default     = true
}
