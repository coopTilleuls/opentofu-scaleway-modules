resource "scaleway_object_bucket" "this" {
  name       = var.name
  project_id = var.project_id
  tags       = var.tags

  dynamic "versioning" {
    for_each = var.versioning_enabled ? [true] : []
    content {
      enabled = true
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      id      = lifecycle_rule.value.id
      enabled = lifecycle_rule.value.enabled
      prefix  = lifecycle_rule.value.prefix

      dynamic "expiration" {
        for_each = lifecycle_rule.value.expiration_days != null ? [lifecycle_rule.value.expiration_days] : []
        content {
          days = expiration.value
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lifecycle_rule.value.noncurrent_version_expiration_days != null ? [lifecycle_rule.value.noncurrent_version_expiration_days] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value
        }
      }
    }
  }
}

locals {
  # var.xxx_id == null serait "unknown" (donc invalide dans un count/for_each) si xxx_id provient
  # d'une ressource créée dans le même apply (ex: application IAM produite par le module
  # `iam-app-identity` juste au-dessus) : sa valeur n'est pas encore connue au moment du plan, mais
  # Terraform/OpenTofu ne peut pas non plus garantir statiquement qu'elle ne sera pas `null`. Les
  # variables enable_sre_access/enable_app_access permettent à l'appelant de trancher explicitement
  # (littéral, donc toujours connu) plutôt que de laisser ce module le déduire de la valeur de l'ID.
  sre_enabled = var.enable_sre_access != null ? var.enable_sre_access : var.sre_group_id != null
  app_enabled = var.enable_app_access != null ? var.enable_app_access : var.app_application_id != null
}

data "scaleway_iam_group" "sre" {
  count = local.sre_enabled ? 1 : 0

  group_id = var.sre_group_id
}

locals {
  # Statement "accès total" pour le groupe SRE : présent dans tous les buckets applicatifs des
  # deux repos d'origine, en plus de l'accès scopé à l'application elle-même. Les deux repos
  # sources résolvent systématiquement le groupe en la liste des `user_id:` de ses membres (jamais
  # `group_id:<id>`, jamais éprouvé en production d'après leurs propres commentaires : "pas de
  # groupe pour l'instant, il faudra surveiller les news").
  sre_statement = local.sre_enabled ? [{
    Sid    = "SreFullAccess"
    Effect = "Allow"
    Principal = {
      SCW = [for user_id in data.scaleway_iam_group.sre[0].user_ids : "user_id:${user_id}"]
    }
    Action = var.sre_actions
    Resource = [
      scaleway_object_bucket.this.name,
      "${scaleway_object_bucket.this.name}/*",
    ]
  }] : []

  app_statement = local.app_enabled ? [{
    Sid    = "ApplicationScopedAccess"
    Effect = "Allow"
    Principal = {
      SCW = "application_id:${var.app_application_id}"
    }
    Action = var.app_actions
    Resource = [
      scaleway_object_bucket.this.name,
      "${scaleway_object_bucket.this.name}/*",
    ]
  }] : []

  policy_statements = concat(local.sre_statement, local.app_statement, var.additional_policy_statements)
}

resource "scaleway_object_bucket_policy" "this" {
  count = length(local.policy_statements) > 0 ? 1 : 0

  bucket     = scaleway_object_bucket.this.name
  project_id = var.project_id
  policy = jsonencode({
    Version   = "2023-04-17"
    Id        = "${var.name}-policy"
    Statement = local.policy_statements
  })
}
