# `lifecycle.prevent_destroy` doit être une constante littérale : impossible de la piloter par
# `var.prevent_destroy` sur une seule ressource. On crée donc deux ressources mutuellement
# exclusives (`count`), une par valeur possible de `var.prevent_destroy`, et `local.bucket`
# (ci-dessous) expose la seule des deux qui existe réellement au reste du module.
resource "scaleway_object_bucket" "this" {
  count = var.prevent_destroy ? 0 : 1

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

resource "scaleway_object_bucket" "protected" {
  count = var.prevent_destroy ? 1 : 0

  lifecycle {
    prevent_destroy = true
  }

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
  bucket = one(concat(scaleway_object_bucket.this, scaleway_object_bucket.protected))
}

data "scaleway_iam_group" "readwrite" {
  for_each = toset(var.readwrite_group_ids)
  group_id = each.key
}

data "scaleway_iam_group" "readonly" {
  for_each = toset(var.readonly_group_ids)
  group_id = each.key
}


locals {
  # Statement "accès total" pour le groupe SRE : présent dans tous les buckets applicatifs des
  # deux repos d'origine, en plus de l'accès scopé à l'application elle-même. Les deux repos
  # sources résolvent systématiquement le groupe en la liste des `user_id:` de ses membres (jamais
  # `group_id:<id>`, jamais éprouvé en production d'après leurs propres commentaires : "pas de
  # groupe pour l'instant, il faudra surveiller les news").
  readwrite_group_statement = length(var.readwrite_group_ids) > 0 ? [{
    Sid    = "ReadWriteUserAccess"
    Effect = "Allow"
    Principal = {
      # tolist() : sans ça, ce for-expression produit un tuple de taille fixe (arité = nombre de
      # membres du groupe), un type cty différent du tuple à 1 élément de app_statement. concat()
      # de deux objets dont un attribut a des tuples de tailles différentes fait planter OpenTofu
      # dès que l'une des deux valeurs est encore inconnue au plan (ex: application_id d'une
      # ressource créée dans le même apply) — cf panic "Error in function call" sur concat(seqs...).
      # pas encore possible via group: https://feature-request.scaleway.com/posts/714/bucket-policy-with-group_id
      SCW = tolist(distinct(flatten([for group_id in var.readwrite_group_ids : [for user_id in data.scaleway_iam_group.readwrite[group_id].user_ids : "user_id:${user_id}"]])))
    }
    Action = var.readwrite_actions
    Resource = [
      local.bucket.name,
      "${local.bucket.name}/*",
    ]
  }] : []

  readonly_group_statement = length(var.readonly_group_ids) > 0 ? [{
    Sid    = "ReadOnlyUserAccess"
    Effect = "Allow"
    Principal = {
      SCW = tolist(distinct(flatten([for group_id in var.readonly_group_ids : [for user_id in data.scaleway_iam_group.readonly[group_id].user_ids : "user_id:${user_id}"]])))
    }
    Action = var.readonly_actions
    Resource = [
      local.bucket.name,
      "${local.bucket.name}/*",
    ]
  }] : []

  app_statement = length(var.application_ids) > 0 ? [{
    Sid    = "ApplicationScopedAccess"
    Effect = "Allow"
    Principal = {
      # tolist() : voir le commentaire équivalent sur readwrite_statement.SCW (même type cty list(string)
      # des deux côtés, indépendamment du nombre d'éléments).
      #SCW = tolist(["application_id:${var.app_application_id}"])
      SCW = tolist([for application_id in var.application_ids : "application_id:${application_id}"])
    }
    Action = var.app_actions
    Resource = [
      local.bucket.name,
      "${local.bucket.name}/*",
    ]
  }] : []

  policy_statements = concat(
    local.readwrite_group_statement,
    local.readonly_group_statement,
    local.app_statement,
    var.additional_policy_statements
  )
}

resource "scaleway_object_bucket_policy" "this" {
  count = length(local.policy_statements) > 0 ? 1 : 0

  bucket     = local.bucket.name
  project_id = var.project_id
  policy = jsonencode({
    Version   = "2023-04-17"
    Id        = "${var.name}-policy"
    Statement = local.policy_statements
  })
}
