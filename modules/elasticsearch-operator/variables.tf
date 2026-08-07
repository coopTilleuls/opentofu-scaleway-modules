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

variable "patch_dir" {
  description = <<-EOT
    Chemin (fourni par le repo consommateur, ex: "$${path.root}/patches/elasticsearch-operator")
    vers un répertoire contenant des fichiers de patch nommés "<Kind>--<name>.yml" (ex:
    "StatefulSet--elastic-operator.yml"). Chaque fichier est appliqué en strategic merge patch sur
    le manifest CRD ou operator correspondant. `null` (défaut) désactive tout patch.
  EOT
  type        = string
  default     = null
}
