# Compte IAM Scaleway dédié à la lecture du Secret Manager (ESO).
resource "scaleway_iam_application" "secret_manager" {
  name = var.name
}

# Politique IAM donnant à cette application un accès en lecture seule au Secret Manager.
resource "scaleway_iam_policy" "secret_read_only" {
  name           = "${var.name}-policy"
  description    = "gives app readonly access to secret manager"
  application_id = scaleway_iam_application.secret_manager.id
  rule {
    project_ids          = [var.project_id]
    permission_set_names = ["SecretManagerReadOnly", "SecretManagerSecretAccess"]
  }
}

# Un secret Scaleway Secret Manager par namespace applicatif, source de l'ExternalSecret.
resource "scaleway_secret" "namespace" {
  for_each = var.namespaces
  name     = each.key
  type     = "key_value"
}

# Référence le secret Scaleway contenant les credentials du compte de service Secret Manager,
# créé manuellement au préalable dans la console Scaleway (cf `bootstrap_secret_name`).
data "scaleway_secret" "secret_manager" {
  name = var.bootstrap_secret_name
}

# Récupère la dernière révision des credentials, utilisée pour peupler le secret K8s bootstrap.
data "scaleway_secret_version" "secret_manager" {
  secret_id = data.scaleway_secret.secret_manager.id
  revision  = "latest"
}

# Secret bootstrap nécessaire pour que le SecretStore puisse s'authentifier auprès du Secret
# Manager Scaleway. Contrairement à AWS/IRSA, Scaleway ne supporte pas l'authentification sans
# credentials explicites. Sans ce secret, le SecretStore reste en erreur "InvalidProviderConfig".
resource "kubernetes_secret_v1" "bootstrap" {
  for_each = var.namespaces
  metadata {
    name      = var.bootstrap_secret_name
    namespace = each.key
  }
  data = {
    access-key        = jsondecode(base64decode(data.scaleway_secret_version.secret_manager.data))["access-key"]
    secret-access-key = jsondecode(base64decode(data.scaleway_secret_version.secret_manager.data))["secret-access-key"]
  }
}

# SecretStore ESO : référence le secret bootstrap pour chaque namespace.
# depends_on garantit que le secret existe avant la création du SecretStore.
resource "kubernetes_manifest" "secret_store" {
  for_each   = var.namespaces
  depends_on = [kubernetes_secret_v1.bootstrap]
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "SecretStore"
    metadata = {
      annotations = {}
      name        = var.secret_store_name
      namespace   = each.key
    }
    spec = {
      provider = {
        scaleway = {
          accessKey = {
            secretRef = {
              key  = "access-key"
              name = var.bootstrap_secret_name
            }
          }
          projectId = var.project_id
          region    = var.region
          secretKey = {
            secretRef = {
              key  = "secret-access-key"
              name = var.bootstrap_secret_name
            }
          }
        }
      }
    }
  }
}

# ExternalSecret : synchronise le secret Scaleway Secret Manager (clé = nom du namespace)
# vers un Secret K8s dans chaque namespace.
resource "kubernetes_manifest" "external_secret" {
  for_each   = var.namespaces
  depends_on = [kubernetes_manifest.secret_store]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = var.external_secret_name
      namespace = each.key
    }
    spec = {
      refreshInterval = var.refresh_interval
      secretStoreRef = {
        kind = "SecretStore"
        name = var.secret_store_name
      }
      target = {
        name           = var.target_secret_name
        creationPolicy = "Owner"
      }
      dataFrom = [
        {
          extract = {
            key = "id:${split("/", scaleway_secret.namespace[each.key].id)[1]}"
          }
        }
      ]
    }
  }
}
