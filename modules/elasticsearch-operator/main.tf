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
  for_each = local.crd_manifests_patched

  manifest = each.value
}

resource "kubernetes_manifest" "operator" {
  depends_on = [kubernetes_manifest.crd]
  for_each   = local.operator_manifests_patched

  manifest = each.value
}

# Patches manuels : si var.patch_dir est renseignée, tout fichier <Kind>--<name>.yml qu'elle
# contient est appliqué en strategic merge patch (mêmes règles qu'un `kubectl patch
# --type=strategic`, ex: les containers sont fusionnés par leur "name", pas par index) sur le
# manifest correspondant, qu'il vienne des CRD ou de l'operator.
locals {
  eck_manifests_raw = merge(local.crd_manifests, local.operator_manifests)

  eck_patch_files = var.patch_dir == null ? [] : fileset(var.patch_dir, "*.yml")
  eck_patches = {
    for f in local.eck_patch_files :
    trimsuffix(f, ".yml") => f
    if contains(keys(local.eck_manifests_raw), trimsuffix(f, ".yml"))
  }
}

data "external" "eck_patch" {
  for_each = local.eck_patches

  program = ["${path.module}/scripts/strategic-merge-patch.sh"]
  query = {
    base  = jsonencode(local.eck_manifests_raw[each.key])
    patch = file("${var.patch_dir}/${each.value}")
  }
}

locals {
  eck_manifests_patched = {
    for key, manifest in local.eck_manifests_raw :
    key => contains(keys(local.eck_patches), key) ? jsondecode(data.external.eck_patch[key].result.merged) : manifest
  }

  crd_manifests_patched      = { for key, manifest in local.crd_manifests : key => local.eck_manifests_patched[key] }
  operator_manifests_patched = { for key, manifest in local.operator_manifests : key => local.eck_manifests_patched[key] }
}
