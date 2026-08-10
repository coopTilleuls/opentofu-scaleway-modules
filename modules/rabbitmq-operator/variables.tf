variable "cluster_operator_version" {
  description = <<-EOT
    Version du RabbitMQ Cluster Operator à installer, ex: "v2.19.2". Utilisée telle quelle dans
    l'URL de téléchargement du manifest officiel
    (https://github.com/rabbitmq/cluster-operator/releases/download/<version>/cluster-operator.yml)
    : voir la liste des releases sur https://github.com/rabbitmq/cluster-operator/releases.
  EOT
  type        = string
}

variable "topology_operator_version" {
  description = <<-EOT
    Version du RabbitMQ Messaging Topology Operator à installer, ex: "v1.19.0". Utilisée telle
    quelle dans l'URL de téléchargement du manifest officiel (variante "with-certmanager", qui
    inclut le webhook de validation) :
    https://github.com/rabbitmq/messaging-topology-operator/releases/download/<version>/messaging-topology-operator-with-certmanager.yaml
    : voir la liste des releases sur
    https://github.com/rabbitmq/messaging-topology-operator/releases.
  EOT
  type        = string
}

variable "patch_dir" {
  description = <<-EOT
    Chemin (fourni par le repo consommateur, ex: "$${path.root}/patches/rabbitmq-operator") vers un
    répertoire contenant des fichiers de patch nommés "<Kind>--<name>.yml" (ex:
    "Deployment--rabbitmq-cluster-operator.yml"). Chaque fichier est appliqué en strategic merge
    patch sur le manifest correspondant, qu'il vienne du cluster operator ou du topology operator.
    `null` (défaut) désactive tout patch.
  EOT
  type        = string
  default     = null
}
