# Rétention des tags du namespace.
#
# Le provider Scaleway n'expose aucune politique de rétention sur `scaleway_registry_namespace`
# (et Container Registry n'en propose pas côté plateforme) : la purge est donc faite par un
# Serverless Job planifié qui exécute `retention.py` contre l'API Registry. Tout est optionnel et
# désactivé tant que `var.retention` vaut null.

locals {
  retention_enabled = var.retention != null
}

# Identité dédiée au job : droits complets sur le Container Registry du projet du namespace,
# identifiants stockés dans Secret Manager et injectés dans le job via `secret_reference`.
module "retention_identity" {
  source = "../iam-app-identity"
  count  = local.retention_enabled ? 1 : 0

  name                 = "${var.name}-retention"
  description          = "Purge planifiée des anciens tags du namespace ${var.name}"
  permission_set_names = ["ContainerRegistryFullAccess"]
  project_ids          = [scaleway_registry_namespace.this.project_id]

  create_secret     = true
  secret_name       = "${var.name}-retention-credentials"
  secret_project_id = scaleway_registry_namespace.this.project_id
}

resource "scaleway_job_definition" "retention" {
  count = local.retention_enabled ? 1 : 0

  name        = "${var.name}-retention"
  description = "Purge des anciens tags du namespace ${var.name}"
  project_id  = scaleway_registry_namespace.this.project_id
  region      = scaleway_registry_namespace.this.region

  image_uri              = var.retention.job_image
  cpu_limit              = 140
  memory_limit           = 256
  local_storage_capacity = 1000
  timeout                = "30m"

  startup_command = ["python3", "-c"]
  args            = [file("${path.module}/retention.py")]

  env = {
    REGION              = scaleway_registry_namespace.this.region
    NAMESPACE_ID        = reverse(split("/", scaleway_registry_namespace.this.id))[0]
    RULES               = jsonencode(var.retention.rules)
    PROTECTED_TAG_REGEX = var.retention.protected_tag_regex
    IMAGE_REGEX         = var.retention.image_regex
    DRY_RUN             = tostring(var.retention.dry_run)
    # Vide = suppression des images sans tag désactivée.
    EMPTY_IMAGE_OLDER_THAN_DAYS = var.retention.empty_image_older_than_days == null ? "" : tostring(var.retention.empty_image_older_than_days)
  }

  secret_reference {
    secret_id   = module.retention_identity[0].secret_id
    environment = "REGISTRY_CREDENTIALS"
  }

  cron {
    schedule = var.retention.schedule
    timezone = var.retention.timezone
  }
}
