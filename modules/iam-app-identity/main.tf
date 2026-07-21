resource "scaleway_iam_application" "this" {
  name        = var.name
  description = var.description
  tags        = var.tags
}

resource "scaleway_iam_api_key" "this" {
  application_id = scaleway_iam_application.this.id
  description    = "Clé API de l'application ${var.name}"
  # Systématiquement renseigné dans toutes les occurrences liées à l'Object Storage des deux
  # repos d'origine (Velero, Loki, CNPG, buckets applicatifs) : sans lui, les clients S3 utilisant
  # cette clé retombent sur le projet par défaut du provider plutôt que sur celui de l'application.
  default_project_id = var.default_project_id
}

resource "scaleway_iam_policy" "this" {
  # Absente dans le seul cas observé d'une application simplement rattachée à un groupe IAM
  # existant (clé CI GitLab de sweeek, membre du groupe "LeadDeveloper" sans policy dédiée) :
  # ce cas est couvert par `iam_group_id` ci-dessous plutôt que par une policy redondante avec
  # les droits du groupe.
  count = length(var.permission_set_names) > 0 ? 1 : 0

  name           = "${var.name}-policy"
  description    = var.description
  application_id = scaleway_iam_application.this.id
  tags           = var.tags

  rule {
    permission_set_names = var.permission_set_names
    # Une rule Scaleway porte soit sur des projets précis, soit sur l'organisation entière :
    # `project_ids` prime si renseigné, sinon on retombe sur `organization_id`.
    project_ids     = length(var.project_ids) > 0 ? var.project_ids : null
    organization_id = length(var.project_ids) > 0 ? null : var.organization_id
  }
}

resource "scaleway_iam_group_membership" "this" {
  # Motif observé pour la clé CI GitLab de sweeek : application rattachée à un groupe IAM
  # existant (ex: "LeadDeveloper") pour hériter de ses droits, sans policy dédiée.
  count = var.iam_group_id != null ? 1 : 0

  group_id       = var.iam_group_id
  application_id = scaleway_iam_application.this.id
}

locals {
  secret_name = coalesce(var.secret_name, "${var.name}-credentials")
  secret_data = coalesce(var.secret_data, jsonencode({
    access_key = scaleway_iam_api_key.this.access_key
    secret_key = scaleway_iam_api_key.this.secret_key
  }))
}

resource "scaleway_secret" "this" {
  count = var.create_secret ? 1 : 0

  name       = local.secret_name
  project_id = var.secret_project_id
  tags       = var.tags
}

resource "scaleway_secret_version" "this" {
  count = var.create_secret ? 1 : 0

  secret_id = scaleway_secret.this[0].id
  data      = local.secret_data
}
