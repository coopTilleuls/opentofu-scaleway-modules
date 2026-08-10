# RabbitMQ Cluster Operator (CRD + operator lui-même) et Messaging Topology Operator (objets
# applicatifs : policies, vhost, users, queues...)
# Cf https://www.rabbitmq.com/kubernetes/operator/operator-overview

data "http" "cluster_operator" {
  url = "https://github.com/rabbitmq/cluster-operator/releases/download/${var.cluster_operator_version}/cluster-operator.yml"
}

data "http" "topology_operator" {
  url = "https://github.com/rabbitmq/messaging-topology-operator/releases/download/${var.topology_operator_version}/messaging-topology-operator-with-certmanager.yaml"
}

locals {
  cluster_operator_manifests = {
    for manifest in provider::kubernetes::manifest_decode_multi(data.http.cluster_operator.response_body) :
    "${manifest.kind}--${manifest.metadata.name}" => manifest
  }

  topology_operator_manifests = {
    # "Namespace--rabbitmq-system" est exclu car il est déjà créé par le cluster operator
    for manifest in provider::kubernetes::manifest_decode_multi(data.http.topology_operator.response_body) :
    "${manifest.kind}--${manifest.metadata.name}" => manifest if manifest.kind != "Namespace" && manifest.metadata.name != "rabbitmq-system"
  }
}

# Cf https://github.com/hashicorp/terraform/issues/29729#issuecomment-2138367809
resource "kubernetes_manifest" "cluster_operator" {
  for_each = local.cluster_operator_manifests_patched

  manifest = each.value
}

resource "kubernetes_manifest" "topology_operator" {
  depends_on = [kubernetes_manifest.cluster_operator]
  for_each   = local.topology_operator_manifests_patched

  manifest = each.value
}

# Patches manuels : si var.patch_dir est renseignée, tout fichier <Kind>--<name>.yml qu'elle
# contient est appliqué en strategic merge patch (mêmes règles qu'un `kubectl patch
# --type=strategic`, ex: les containers sont fusionnés par leur "name", pas par index) sur le
# manifest correspondant, qu'il vienne du cluster operator ou du topology operator.
locals {
  rabbitmq_manifests_raw = merge(local.cluster_operator_manifests, local.topology_operator_manifests)

  rabbitmq_patch_files = var.patch_dir == null ? [] : fileset(var.patch_dir, "*.yml")
  rabbitmq_patches = {
    for f in local.rabbitmq_patch_files :
    trimsuffix(f, ".yml") => f
    if contains(keys(local.rabbitmq_manifests_raw), trimsuffix(f, ".yml"))
  }
}

data "external" "rabbitmq_patch" {
  for_each = local.rabbitmq_patches

  program = ["${path.module}/scripts/strategic-merge-patch.sh"]
  query = {
    base  = jsonencode(local.rabbitmq_manifests_raw[each.key])
    patch = file("${var.patch_dir}/${each.value}")
  }
}

locals {
  rabbitmq_manifests_patched = {
    for key, manifest in local.rabbitmq_manifests_raw :
    key => contains(keys(local.rabbitmq_patches), key) ? jsondecode(data.external.rabbitmq_patch[key].result.merged) : manifest
  }

  cluster_operator_manifests_patched  = { for key, manifest in local.cluster_operator_manifests : key => local.rabbitmq_manifests_patched[key] }
  topology_operator_manifests_patched = { for key, manifest in local.topology_operator_manifests : key => local.rabbitmq_manifests_patched[key] }
}
