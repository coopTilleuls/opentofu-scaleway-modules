variable "name" {
  description = "Nom du VPC Scaleway."
  type        = string
}

variable "project_id" {
  description = "ID du projet Scaleway auquel rattacher le VPC et ses sous-ressources. Laisser à null pour utiliser le projet par défaut du provider."
  type        = string
  default     = null
}

variable "enable_routing" {
  description = "Active le routage entre les private networks du VPC."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources créées par ce module."
  type        = list(string)
  default     = []
}

variable "private_networks" {
  description = <<-EOT
    Private networks à créer dans le VPC, indexés par un nom logique (ex: "kubernetes", "tools").
    `subnet` doit être le CIDR IPv4 complet de ce private network : le calcul (ex. via `cidrsubnet()`)
    est laissé à la charge du module appelant, pour que ce module reste agnostique du plan d'adressage
    global du projet.
  EOT
  type = map(object({
    subnet = string
  }))
  default = {}
}

variable "public_gateways" {
  description = <<-EOT
    Public gateways à créer, indexées par un nom logique (ex: "kubernetes"). Une gateway est créée
    par zone listée dans `zones`, toutes rattachées au private network désigné par `private_network_key`
    (qui doit correspondre à une clé présente dans `var.private_networks`).
  EOT
  type = map(object({
    private_network_key = string
    zones               = list(string)
    type                = optional(string, "VPC-GW-S")
    enable_masquerade   = optional(bool, true)
    push_default_route  = optional(bool, true)
  }))
  default = {}
}

variable "reserved_lb_ips" {
  description = <<-EOT
    IPs flottantes de load-balancer à réserver à l'avance, indexées par un nom logique (ex: "nginx-ingress").
    Une IP est réservée par zone listée dans `zones`. Utile pour figer l'IP d'un ingress controller avant
    même de configurer le DNS, sans pour autant créer le load balancer lui-même.
  EOT
  type = map(object({
    zones = list(string)
  }))
  default = {}
}
