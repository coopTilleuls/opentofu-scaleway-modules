# ECK (Elastic Cloud on Kubernetes) operator
# Cf https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/k8s-openshift-deploy-operator

data "http" "eck_crds" {
  url = "https://download.elastic.co/downloads/eck/${var.eck_version}/crds.yaml"
}

data "http" "eck_operator" {
  url = "https://download.elastic.co/downloads/eck/${var.eck_version}/operator.yaml"
}

locals {
  crd_manifests = {
    for manifest in provider::kubernetes::manifest_decode_multi(data.http.eck_crds.response_body) :
    "${manifest.kind}--${manifest.metadata.name}" => manifest
  }

  operator_manifests = {
    for manifest in provider::kubernetes::manifest_decode_multi(data.http.eck_operator.response_body) :
    "${manifest.kind}--${manifest.metadata.name}" => manifest
  }
}

# Cf https://github.com/hashicorp/terraform/issues/29729#issuecomment-2138367809
resource "kubernetes_manifest" "crd" {
  for_each = local.crd_manifests

  manifest = each.value
}

resource "kubernetes_manifest" "operator" {
  depends_on = [kubernetes_manifest.crd]
  for_each   = local.operator_manifests

  manifest = each.value
}
