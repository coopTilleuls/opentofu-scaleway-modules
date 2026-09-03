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

locals {
  policy_condition = join("||", [for allowed_secret_id in var.allowed_secrets_ids : "resource.id == \"${split("/",allowed_secret_id)[1]}\"" ])
  # https://www.scaleway.com/en/docs/iam/reference-content/understanding-resource-level-conditions/#resource-level-conditions-and-listing-actions
  policy_list_condition = "(${local.policy_condition}) || !has(resource.id)"
  secret_store_name = "secretstore-${var.name}"
}

# Politique IAM donnant à cette application un accès en lecture seule au Secret Manager.
resource "scaleway_iam_policy" "secret_read_only" {
  name           = "eso-${var.name}-${terraform.workspace}"
  description    = "gives app readonly access to secret manager"
  application_id = scaleway_iam_application.external_secret.id
  rule {
    project_ids          = [var.project_id]
    permission_set_names = ["SecretManagerReadOnly", "SecretManagerSecretAccess"]
    #condition = local.policy_condition
    condition = local.policy_list_condition
  }
}

# Secret bootstrap nécessaire pour que le SecretStore puisse s'authentifier auprès du Secret
# Manager Scaleway. Contrairement à AWS/IRSA, Scaleway ne supporte pas l'authentification sans
# credentials explicites. Sans ce secret, le SecretStore reste en erreur "InvalidProviderConfig".
resource "kubernetes_secret_v1" "external_secret_credentials" {
  for_each = var.namespaces
  metadata {
    name      = local.secret_store_name
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
  depends_on = [kubernetes_secret_v1.external_secret_credentials]
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "SecretStore"
    metadata = {
      annotations = {}
      name        = "secretstore-${var.name}"
      namespace   = each.key
    }
    spec = {
      provider = {
        scaleway = {
          accessKey = {
            secretRef = {
              key  = "access-key"
		name = local.secret_store_name
            }
          }
          projectId = var.project_id
          region    = var.region
          secretKey = {
            secretRef = {
              key  = "secret-access-key"
              name = local.secret_store_name
            }
          }
        }
      }
    }
  }
}
