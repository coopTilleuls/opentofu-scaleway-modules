resource "random_password" "admin" {
  # Généré seulement si l'appelant ne fournit pas son propre mot de passe. Contraintes de
  # complexité alignées sur les exigences Scaleway (au moins 1 majuscule/minuscule/chiffre/
  # caractère spécial) pour éviter un rejet aléatoire de l'API selon le tirage.
  count = var.admin_password == null ? 1 : 0

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

locals {
  admin_password = var.admin_password != null ? var.admin_password : random_password.admin[0].result
}

resource "scaleway_rdb_instance" "this" {
  # Une instance de production ne doit jamais pouvoir être détruite par un `tofu apply`/
  # `destroy` accidentel. `prevent_destroy` doit être une constante littérale : la déprotéger
  # nécessite une modification volontaire de ce fichier.
  lifecycle {
    prevent_destroy = true
  }

  name       = var.name
  project_id = var.project_id
  region     = var.region

  node_type     = var.node_type
  engine        = var.engine_version
  is_ha_cluster = var.is_ha_cluster

  user_name = var.admin_user_name
  password  = local.admin_password

  disable_backup            = var.disable_backup
  backup_schedule_frequency = var.backup_schedule_frequency
  backup_schedule_retention = var.backup_schedule_retention
  backup_same_region        = var.backup_same_region

  volume_type        = var.volume_type
  volume_size_in_gb  = var.volume_type == "lssd" ? null : var.volume_size_in_gb
  encryption_at_rest = var.encryption_at_rest

  settings = var.settings

  tags = var.tags

  private_network {
    pn_id       = var.private_network_id
    enable_ipam = true
  }
}

resource "scaleway_rdb_database" "this" {
  for_each = toset(var.databases)

  instance_id = scaleway_rdb_instance.this.id
  name        = each.key
}

resource "random_password" "user" {
  # Un mot de passe dédié par base, uniquement si des utilisateurs dédiés sont demandés.
  for_each = var.create_dedicated_users ? toset(var.databases) : []

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "scaleway_rdb_user" "this" {
  for_each = var.create_dedicated_users ? toset(var.databases) : []

  instance_id = scaleway_rdb_instance.this.id
  name        = each.key
  password    = random_password.user[each.key].result
  is_admin    = false
}

resource "scaleway_rdb_privilege" "this" {
  for_each = var.create_dedicated_users ? toset(var.databases) : []

  instance_id   = scaleway_rdb_instance.this.id
  user_name     = scaleway_rdb_user.this[each.key].name
  database_name = scaleway_rdb_database.this[each.key].name
  permission    = "all"
}
