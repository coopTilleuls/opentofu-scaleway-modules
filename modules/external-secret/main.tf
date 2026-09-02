# Compte IAM Scaleway dédié à la lecture du Secret Manager (ESO).
resource "scaleway_iam_application" "external_secret" {
  name = "eso-${var.name}-${terraform.workspace}"
}

resource "scaleway_iam_api_key" "external_secret" {
  application_id = scaleway_iam_application.external_secret.id
  description    = "eso-${var.name}-${terraform.workspace}"
}

# secret contentant le compte
resource "scaleway_secret" "external_secret" {
  name        = "eso-${var.name}-${terraform.workspace}"
  description = "api key pour external secret ${var.name} ${terraform.workspace}"
  type        = "key_value"
}

resource "scaleway_secret_version" "external_secret_version" {
  description = "Version 1"
  secret_id   = scaleway_secret.external_secret.id
  data        = jsonencode(
    {
      "access-key"        = scaleway_iam_api_key.external_secret.access_key
      "secret-access-key" = scaleway_iam_api_key.external_secret.secret_key
    }
  )
}

data "scaleway_secret" "by_name" {
  for_each = var.allowed_secrets
  name = each.key
}

locals {
  policy_condition = join("||", [for allowed_secret in data.scaleway_secret.by_name : "resource.id == \"${split("/",allowed_secret.secret_id)[1]}\"" ])
}

# Politique IAM donnant à cette application un accès en lecture seule au Secret Manager.
resource "scaleway_iam_policy" "secret_read_only" {
  name           = "eso-${var.name}-${terraform.workspace}"
  description    = "gives app readonly access to secret manager"
  application_id = scaleway_iam_application.external_secret.id
  rule {
    project_ids          = [var.project_id]
    permission_set_names = ["SecretManagerReadOnly", "SecretManagerSecretAccess"]
    condition = local.policy_condition
  }
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
    access-key        = jsondecode(base64decode(scaleway_secret_version.external_secret_version.data))["access-key"]
    secret-access-key = jsondecode(base64decode(scaleway_secret_version.external_secret_version.data))["secret-access-key"]
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

## ExternalSecret : synchronise le secret Scaleway Secret Manager (clé = nom du namespace)
## vers un Secret K8s dans chaque namespace.
#resource "kubernetes_manifest" "external_secret" {
#  for_each   = var.namespaces
#  depends_on = [kubernetes_manifest.secret_store]
#
#  manifest = {
#    apiVersion = "external-secrets.io/v1"
#    kind       = "ExternalSecret"
#    metadata = {
#      name      = var.external_secret_name
#      namespace = each.key
#    }
#    spec = {
#      refreshInterval = var.refresh_interval
#      secretStoreRef = {
#        kind = "SecretStore"
#        name = var.secret_store_name
#      }
#      target = {
#        name           = var.target_secret_name
#        creationPolicy = "Owner"
#      }
#      dataFrom = [
#        {
#          extract = {
#            key = "id:${split("/", scaleway_secret.namespace[each.key].id)[1]}"
#          }
#        }
#      ]
#    }
#  }
#}
