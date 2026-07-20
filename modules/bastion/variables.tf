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

variable "ansible_playbook_path" {
  description = <<-EOT
    Chemin vers un playbook Ansible (ex: "$${path.root}/ansible/playbook.yml") exécuté contre le
    bastion via SSH juste après son démarrage. Laisser à null (défaut) pour ne pas exécuter
    Ansible : le bastion reste alors uniquement configuré par `user_data` (cloud-init).

    Motif repris de opentofu-ffspt : la configuration ré-appliquable (comptes utilisateurs...) est
    mieux gérée par un playbook Ansible idempotent, ré-exécuté à chaque changement (piloté par
    `ansible_triggers`), que par du cloud-init qui ne s'exécute qu'une seule fois au premier boot.
  EOT
  type        = string
  default     = null
}

variable "ansible_ssh_user" {
  description = "Utilisateur SSH utilisé pour se connecter au bastion et exécuter Ansible."
  type        = string
  default     = "admin"
}

variable "ansible_extra_vars_file" {
  description = "Fichier de variables Ansible (`-e @fichier`) passé à `ansible-playbook`, par exemple le group_vars du repo consommateur. Laisser à null pour ne pas en passer."
  type        = string
  default     = null
}

variable "ansible_triggers" {
  description = <<-EOT
    Map de valeurs (typiquement des `filemd5(...)` sur le playbook et ses fichiers de variables)
    dont un changement déclenche une ré-exécution d'Ansible sur le bastion déjà existant, sans le
    recréer. Laisser vide pour ne l'exécuter qu'à la création du bastion.
  EOT
  type        = map(string)
  default     = {}
}
