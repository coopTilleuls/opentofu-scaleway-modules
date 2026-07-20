variable "name" {
  description = "Nom du cluster Kapsule."
  type        = string
}

variable "project_id" {
  description = "ID du projet Scaleway auquel rattacher le cluster. Laisser à null pour utiliser le projet par défaut du provider."
  type        = string
  default     = null
}

variable "region" {
  description = "Région Scaleway du cluster. Laisser à null pour utiliser la région par défaut du provider."
  type        = string
  default     = null
}

variable "version_prefix" {
  description = "Version de Kubernetes du cluster (ex: \"1.35\"). Correspond à l'argument `version` de `scaleway_k8s_cluster` (renommé ici pour ne pas entrer en conflit avec le mot réservé `version`)."
  type        = string
}

variable "type" {
  description = "Type de cluster Kapsule (ex: \"kapsule\", \"kapsule-dedicated-4\", \"kapsule-dedicated-8\"...). Impacte le coût et les capacités du control plane managé."
  type        = string
  default     = "kapsule"
}

variable "cni" {
  description = "Plugin CNI du cluster."
  type        = string
  default     = "cilium"
}

variable "delete_additional_resources" {
  description = "Supprime les ressources additionnelles (load balancers, volumes) créées par le cluster lors de sa destruction."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags appliqués au cluster et, en complément de leurs propres tags, à tous les pools."
  type        = list(string)
  default     = []
}

variable "private_network_id" {
  description = "ID du private network sur lequel rattacher le cluster (généralement produit par le module `vpc`)."
  type        = string
}

variable "autoscaler_config" {
  description = "Configuration du cluster-autoscaler du cluster. Les valeurs par défaut reprennent celles utilisées en production sur les projets existants."
  type = object({
    scale_down_delay_after_add       = optional(string, "1m")
    scale_down_unneeded_time         = optional(string, "1m")
    estimator                        = optional(string, "binpacking")
    expander                         = optional(string, "least_waste")
    ignore_daemonsets_utilization    = optional(bool, true)
    balance_similar_node_groups      = optional(bool, true)
    scale_down_utilization_threshold = optional(number, 0.9)
  })
  default = {}
}

variable "auto_upgrade" {
  description = "Configuration de la mise à jour automatique du control plane. `enable = false` désactive complètement le bloc `auto_upgrade`."
  type = object({
    enable                        = optional(bool, true)
    maintenance_window_day        = optional(string, "any")
    maintenance_window_start_hour = optional(number, 5)
  })
  default = {}
}

variable "open_id_connect_config" {
  description = <<-EOT
    Configuration OIDC pour l'authentification au cluster (ex: OIDC GitLab utilisé pour donner
    accès en lecture/écriture aux développeurs sans distribuer de kubeconfig statique). Laisser
    à null pour ne pas activer l'OIDC.
  EOT
  type = object({
    issuer_url      = string
    client_id       = string
    username_claim  = optional(string)
    username_prefix = optional(string)
    groups_claim    = optional(list(string))
    groups_prefix   = optional(string)
    required_claim  = optional(list(string), [])
  })
  default = null
}

variable "pools" {
  description = <<-EOT
    Pools de nodes à créer, indexés par un nom logique (ex: "default", "web", "spot"). Une seule
    entrée peut suffire (cas simple : un pool par zone), ou une matrice plus riche (taille/type/zone/
    taints par pool, cas des clusters multi-usages avec des pools dédiés et des taints).
  EOT
  type = map(object({
    zone                   = string
    node_type              = string
    size                   = number
    min_size               = optional(number, 0)
    max_size               = optional(number)
    autoscaling            = optional(bool, true)
    autohealing            = optional(bool, true)
    container_runtime      = optional(string, "containerd")
    root_volume_size_in_gb = optional(number, 20)
    public_ip_disabled     = optional(bool, true)
    tags                   = optional(list(string), [])
    labels                 = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
}

variable "pool_upgrade_policy" {
  description = "Politique de rolling-upgrade appliquée à tous les pools (mêmes valeurs pour tous, pas de granularité par pool)."
  type = object({
    max_surge       = optional(number, 1)
    max_unavailable = optional(number, 1)
  })
  default = {}
}

variable "network_dependencies" {
  description = <<-EOT
    Références de ressources (ex: `module.vpc.gateway_network_ids`) dont la création doit être
    terminée avant celle des pools. Sert uniquement à alimenter un `depends_on` explicite : la
    gateway réseau met un peu de temps à propager sa route par défaut après sa création, et les
    nodes échouent parfois à sortir sur Internet si les pools sont créés immédiatement après.
  EOT
  type        = any
  default     = []
}

variable "wait_after_network_seconds" {
  description = "Délai d'attente (en secondes) après la création du réseau/de la gateway, avant de créer les pools."
  type        = number
  default     = 60
}

variable "install_kubeconfig" {
  description = <<-EOT
    Si `true`, exécute `scw k8s kubeconfig install <cluster_id>` en local-exec après la création
    du cluster (nécessite le CLI `scw` installé et configuré sur la machine qui exécute `tofu apply`).
    Pratique en poste de dev, à éviter en CI où cette commande n'a généralement pas d'effet utile.
  EOT
  type        = bool
  default     = false
}
