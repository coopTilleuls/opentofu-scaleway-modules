variable "type" {
  description = <<-EOT
    Type de ressource surveillée, qui détermine le jeu de règles créé :
    `kubernetes` (ETCD / API server Kapsule), `s2s_vpn`, `public_gateway`, `postgresql`,
    `opensearch`.
  EOT
  type        = string

  validation {
    condition     = contains(["kubernetes", "s2s_vpn", "public_gateway", "postgresql", "opensearch"], var.type)
    error_message = "type doit valoir kubernetes, s2s_vpn, public_gateway, postgresql ou opensearch."
  }
}

variable "service_level" {
  description = <<-EOT
    Niveau de service de la ressource, posé en label `service_level` sur chaque alerte :
    - `24/7` : les alertes critical partent toujours vers le webhook critical.
    - `5/7` : les alertes critical ne partent vers le webhook critical qu'aux heures ouvrées
      (cf. `business_hours` du module `cockpit-alerting`), et vers le webhook warning le reste du
      temps.
    Le routage lui-même est fait par le module `cockpit-alerting` (>= 3.0.0).
  EOT
  type        = string

  validation {
    condition     = contains(["24/7", "5/7"], var.service_level)
    error_message = "service_level doit valoir \"24/7\" ou \"5/7\"."
  }
}

variable "resource_name" {
  description = <<-EOT
    Nom Scaleway de la ressource surveillée (label `resource_name` des métriques Cockpit), ex. le
    nom de l'instance RDB. Les expressions sont filtrées sur ce nom. Laisser à `null` pour couvrir
    toutes les ressources du type dans le projet (une seule instance du module par type dans ce
    cas, sinon les alertes seront en double).
  EOT
  type        = string
  default     = null
}

variable "public_gateway_size" {
  description = "Taille de la public gateway (S/M/L/XL), obligatoire si `type = \"public_gateway\"`. Sert à calculer le taux d'utilisation de la bande passante tant qu'aucune métrique n'expose la capacité."
  type        = string
  default     = null

  validation {
    condition     = var.public_gateway_size == null || contains(["S", "M", "L", "XL"], coalesce(var.public_gateway_size, "S"))
    error_message = "public_gateway_size doit valoir S, M, L ou XL."
  }
}

variable "labels" {
  description = "Labels additionnels posés sur chaque alerte (ex. `{ team = \"sre\" }`). `severity` et `service_level` sont réservés et écrasés par le module."
  type        = map(string)
  default     = {}
}

variable "project_id" {
  description = "ID du projet Scaleway dont on récupère les alertes préconfigurées Cockpit (types `postgresql`). Laisser à null pour utiliser le projet par défaut du provider."
  type        = string
  default     = null
}

variable "region" {
  description = "Région Scaleway des alertes préconfigurées Cockpit. Laisser à null pour utiliser la région par défaut du provider."
  type        = string
  default     = null
}
