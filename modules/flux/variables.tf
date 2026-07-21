variable "git_repository_url" {
  description = <<-EOT
    URL SSH du repo Git contenant les manifests Flux (ex:
    "ssh://git@github.com/<org>/<repo>" ou "ssh://git@gitlab.com/<group>/<repo>"). Propre à
    chaque repo consommateur, pas de valeur par défaut.
  EOT
  type        = string
}

variable "git_branch" {
  description = "Branche du repo Git Flux suivie par la GitRepository (ex: \"main\", \"staging\")."
  type        = string
}

variable "git_known_hosts" {
  description = <<-EOT
    Clé(s) publique(s) SSH de l'hébergeur Git, au format known_hosts (ex: sortie de
    `ssh-keyscan github.com`), utilisée pour vérifier l'hôte lors du clone. Diffère selon
    l'hébergeur (GitHub, GitLab, auto-hébergé), pas de valeur par défaut.
  EOT
  type        = string
}

variable "git_repository_interval" {
  description = "Intervalle de resynchronisation de la GitRepository Flux."
  type        = string
  default     = "1m0s"
}

variable "git_repository_timeout" {
  description = "Timeout du clone Git par la GitRepository Flux."
  type        = string
  default     = "60s"
}

variable "kustomization_path" {
  description = <<-EOT
    Chemin, dans le repo Git Flux, du Kustomization racine à réconcilier (ex:
    "./clusters/mon-cluster"). La convention de chemin ("clusters/<nom-du-cluster>"...) est
    propre à chaque repo consommateur, pas de valeur par défaut.
  EOT
  type        = string
}

variable "kustomization_interval" {
  description = "Intervalle de réconciliation de la Kustomization flux-system."
  type        = string
  default     = "10m0s"
}

variable "kustomization_prune" {
  description = "Active le prune (suppression des objets qui ne sont plus dans le repo Git) sur la Kustomization flux-system."
  type        = bool
  default     = true
}

variable "kustomization_force" {
  description = "Force le recréation des ressources immuables sur la Kustomization flux-system."
  type        = bool
  default     = false
}

variable "enable_sealed_secrets" {
  description = <<-EOT
    Génère la paire clé/certificat (`tls_private_key`/`tls_self_signed_cert`) et le secret
    "sealed-secrets-key" utilisés par le controller sealed-secrets. Mettre à `false` si le repo
    consommateur ne déploie pas sealed-secrets ou gère sa clé autrement.
  EOT
  type        = bool
  default     = true
}

variable "flux_install_kubectl_context" {
  description = <<-EOT
    Contexte kubeconfig (`--context`) utilisé par le binaire `flux` local pour installer les
    controllers (`flux install`, exécuté via `local-exec` sur la machine qui lance `tofu apply`).
    Laisser à `null` (défaut) pour utiliser le contexte courant.

    Nécessite que le CLI `flux` soit installé et qu'un kubeconfig valide pour ce cluster soit
    disponible sur la machine qui exécute `tofu apply` : ce module reprend tel quel le bootstrap
    "maison" des repos d'origine (pas le provider officiel `fluxcd/flux`), y compris ses
    contraintes opérationnelles (CLI local requis, double `tofu apply` nécessaire au premier
    bootstrap : voir le README de ce module).
  EOT
  type        = string
  default     = null
}

variable "terraform_outputs_data" {
  description = <<-EOT
    Données exposées via la ConfigMap "terraform-outputs" (namespace flux-system), destinées à
    être consommées par les Kustomization Flux via `postBuild.substituteFrom`. Laisser vide
    (défaut) si non utilisé. Le contenu (clés/valeurs) est entièrement propre à chaque repo
    consommateur (ex: IPs de load-balancers à substituer dans des manifests).
  EOT
  type        = map(string)
  default     = {}
}
