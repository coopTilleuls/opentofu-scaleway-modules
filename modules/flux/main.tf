resource "kubernetes_namespace_v1" "flux_system" {
  metadata {
    name = "flux-system"
  }

  lifecycle {
    # Les labels/annotations de ce namespace sont ensuite gérés par Flux lui-même
    # (kustomize.toolkit.fluxcd.io/...) une fois le bootstrap terminé.
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

resource "tls_private_key" "flux_system" {
  # Clé de déploiement SSH utilisée par Flux pour cloner le repo Git. Sa rotation casserait
  # l'accès de Flux au repo tant que la clé publique n'est pas remplacée côté hébergeur (deploy
  # key), d'où le prevent_destroy.
  algorithm = "RSA"
  rsa_bits  = 4096

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_secret_v1" "flux_system" {
  metadata {
    name      = "flux-system"
    namespace = kubernetes_namespace_v1.flux_system.metadata[0].name
  }

  data = {
    known_hosts    = var.git_known_hosts
    identity       = tls_private_key.flux_system.private_key_pem
    "identity.pub" = tls_private_key.flux_system.public_key_openssh
  }

  wait_for_service_account_token = false
}

resource "tls_private_key" "sealed_secrets" {
  count = var.enable_sealed_secrets ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096

  lifecycle {
    prevent_destroy = true
  }
}

resource "tls_self_signed_cert" "sealed_secrets" {
  count = var.enable_sealed_secrets ? 1 : 0

  private_key_pem       = tls_private_key.sealed_secrets[0].private_key_pem
  validity_period_hours = 24 * 365 * 10 # 10 ans
  allowed_uses = [
    "key_encipherment",
  ]
}

resource "kubernetes_secret_v1" "sealed_secrets" {
  count = var.enable_sealed_secrets ? 1 : 0

  metadata {
    name      = "sealed-secrets-key"
    namespace = kubernetes_namespace_v1.flux_system.metadata[0].name
  }

  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = tls_self_signed_cert.sealed_secrets[0].cert_pem
    "tls.key" = tls_private_key.sealed_secrets[0].private_key_pem
  }

  wait_for_service_account_token = false
}

data "kubernetes_resources" "flux_deployment" {
  api_version    = "apps/v1"
  kind           = "Deployment"
  namespace      = kubernetes_namespace_v1.flux_system.metadata[0].name
  field_selector = "metadata.name==helm-controller"
}

resource "null_resource" "flux_install" {
  # N'installe les controllers Flux (via le CLI `flux`, en local-exec) que s'ils ne sont pas déjà
  # présents dans le cluster : au premier bootstrap le cluster ne contient encore aucun CRD Flux,
  # ce qui empêche de créer les kubernetes_manifest GitRepository/Kustomization dans le même
  # apply (cf README : bootstrap en deux `tofu apply`).
  count = length(data.kubernetes_resources.flux_deployment.objects) == 0 ? 1 : 0

  provisioner "local-exec" {
    command = join(" ", compact([
      "flux install",
      var.flux_install_kubectl_context != null ? "--context ${var.flux_install_kubectl_context}" : "",
      "&& sleep 15",
    ]))
  }
}

resource "kubernetes_config_map_v1" "terraform_outputs" {
  metadata {
    name      = "terraform-outputs"
    namespace = kubernetes_namespace_v1.flux_system.metadata[0].name
  }

  depends_on = [
    kubernetes_namespace_v1.flux_system,
  ]

  data = var.terraform_outputs_data
}

resource "kubernetes_manifest" "flux_gitrepo" {
  # Ne peut être créé qu'une fois les CRD Flux installés (cf null_resource.flux_install) : sur un
  # cluster tout neuf, ce manifest est donc absent du premier apply et n'apparaît qu'au second.
  count = length(data.kubernetes_resources.flux_deployment.objects) == 0 ? 0 : 1

  depends_on = [
    null_resource.flux_install,
  ]

  manifest = {
    "apiVersion" = "source.toolkit.fluxcd.io/v1"
    "kind"       = "GitRepository"
    "metadata" = {
      "name"      = "flux-system"
      "namespace" = kubernetes_namespace_v1.flux_system.metadata[0].name
    }
    "spec" = {
      "interval" = var.git_repository_interval
      "ref" = {
        "branch" = var.git_branch
      }
      "secretRef" = {
        "name" = kubernetes_secret_v1.flux_system.metadata[0].name
      }
      "timeout" = var.git_repository_timeout
      "url"     = var.git_repository_url
    }
  }

  field_manager {
    # Autorise à changer `git_branch` sans que le field-manager du CLI `flux` (utilisé lors du
    # premier bootstrap) n'entre en conflit avec celui d'OpenTofu sur les applies suivants.
    name            = "opentofu-scaleway-modules-flux"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "flux_kustomization_flux_system" {
  count = length(data.kubernetes_resources.flux_deployment.objects) == 0 ? 0 : 1

  depends_on = [
    null_resource.flux_install,
  ]

  manifest = {
    "apiVersion" = "kustomize.toolkit.fluxcd.io/v1"
    "kind"       = "Kustomization"
    "metadata" = {
      "name"      = "flux-system"
      "namespace" = kubernetes_namespace_v1.flux_system.metadata[0].name
    }
    "spec" = {
      "force"    = var.kustomization_force
      "interval" = var.kustomization_interval
      "path"     = var.kustomization_path
      "prune"    = var.kustomization_prune
      "sourceRef" = {
        "kind" = "GitRepository"
        "name" = "flux-system"
      }
    }
  }
}
