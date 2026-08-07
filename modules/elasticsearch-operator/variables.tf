variable "eck_version" {
  description = <<-EOT
    Version d'ECK (Elastic Cloud on Kubernetes) à installer, ex: "3.5.0". Utilisée telle quelle
    dans les URLs de téléchargement des manifests officiels
    (https://download.elastic.co/downloads/eck/<version>/{crds,operator}.yaml) : voir la liste des
    versions disponibles sur
    https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/k8s-openshift-deploy-operator.
  EOT
  type        = string
}
