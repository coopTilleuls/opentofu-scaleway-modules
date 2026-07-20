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
  # Statement "accès total" pour le groupe SRE : présent dans tous les buckets applicatifs des
  # deux repos d'origine, en plus de l'accès scopé à l'application elle-même.
  sre_statement = var.sre_group_id == null ? [] : [{
    Sid    = "SreFullAccess"
    Effect = "Allow"
    Principal = {
      SCW = "group_id:${var.sre_group_id}"
    }
    Action = var.sre_actions
    Resource = [
      scaleway_object_bucket.this.name,
      "${scaleway_object_bucket.this.name}/*",
    ]
  }]

  app_statement = var.app_application_id == null ? [] : [{
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
  }]

  policy_statements = concat(local.sre_statement, local.app_statement, var.additional_policy_statements)
}

resource "scaleway_object_bucket_policy" "this" {
  count = length(local.policy_statements) > 0 ? 1 : 0

  bucket = scaleway_object_bucket.this.name
  policy = jsonencode({
    Version   = "2023-04-17"
    Id        = "${var.name}-policy"
    Statement = local.policy_statements
  })
}
