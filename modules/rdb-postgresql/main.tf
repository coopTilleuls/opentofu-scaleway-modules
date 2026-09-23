resource "random_password" "admin" {
  lifecycle {
    # do not replace imported shortests passwords
    ignore_changes = [
      length,
      min_lower,
      min_numeric,
      min_special,
      min_upper,
      override_special
    ]
  }

  # Généré seulement si l'appelant ne fournit pas son propre mot de passe. Contraintes de
  # complexité alignées sur les exigences Scaleway (au moins 1 majuscule/minuscule/chiffre/
  # caractère spécial) pour éviter un rejet aléatoire de l'API selon le tirage.
  count = var.admin_password == null ? 1 : 0

  length  = 32
  special = true
  # Restreint aux caractères sans risque d'interprétation particulière dans une DSN
  # "postgresql://user:password@host:port/db" ou lors d'un export shell (les deux repos d'origine
  # utilisaient déjà un jeu volontairement restreint pour cette même raison, documentée en
  # commentaire dans leur code : "only chars allowed in ...@... on export var=password").
  override_special = "_"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

locals {
  admin_password = var.admin_password != null ? var.admin_password : random_password.admin[0].result

  node_type_cpu = {
    "DB-DEV-S" = 2
    "DB-DEV-M" = 3
    "DB-DEV-L" = 4
    "DB-DEV-XL" = 4
    # ...
    "DB-POP2-2C-8G" = 2
    "DB-POP2-4C-16G" = 4
    "DB-POP2-8C-32G" = 8
    "DB-POP2-16C-64G" = 16
    "DB-POP2-32C-128G" = 32
  }
  node_type_mem = {
    "DB-DEV-S" = 2
    "DB-DEV-M" = 4
    "DB-DEV-L" = 8
    "DB-DEV-XL" = 12
    # ...
    "DB-POP2-2C-8G" = 8
    "DB-POP2-4C-16G" = 16
    "DB-POP2-8C-32G" = 32
    "DB-POP2-16C-64G" = 64
    "DB-POP2-32C-128G" = 128
  }
  volume_type_cost = {
    lssd = 1.1 # local = local latency only
    sbs_5k = 1.5
    sbs_15k = 1.2
  }

  # Some settings are dependent of the instance size and/or storage type
  computed_settings = {

    # effective_cache_size : 50% of memory if nothing specified (hot reload)
    effective_cache_size = lookup(local.node_type_mem,var.node_type)*1024/2

    # max_parallel_workers : number of cpu (hot reload)
    max_parallel_workers = lookup(local.node_type_cpu,var.node_type)

    # max_parallel_workers_per_gather : 1/4 of cpu count (hot reload)
    max_parallel_workers_per_gather = max(lookup(local.node_type_cpu,var.node_type)/4,2)

    # max_connections : depends of available memory (NEEDS RESTART)
    max_connections = min(lookup(local.node_type_mem,var.node_type)*1024/8,2000)

    # random_page_cost and seq_page_cost depends of the volume type (hot reload)
    random_page_cost = lookup(local.volume_type_cost,var.volume_type)
    seq_page_cost = lookup(local.volume_type_cost,var.volume_type)

  }

  # we merge computed settings with user settings
  # when set, user settings takes precedence
  merged_settings = merge(local.computed_settings, var.settings)
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

  settings = local.merged_settings

  tags = var.tags

  private_network {
    pn_id       = var.private_network_id
    enable_ipam = true
  }
}

resource "scaleway_rdb_database" "this" {
  for_each = toset(var.databases)

  instance_id = scaleway_rdb_instance.this.id
  name        = "${each.key}_${terraform.workspace}"
}

resource "random_password" "user" {
  lifecycle {
    # do not replace imported shortests passwords
    ignore_changes = [
      length,
      min_lower,
      min_numeric,
      min_special,
      min_upper,
      override_special
    ]
  }

  # Un mot de passe dédié par base, uniquement si des utilisateurs dédiés sont demandés.
  for_each = var.create_dedicated_users ? toset(var.databases) : []

  length           = 32
  special          = true
  override_special = "_"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "random_password" "user_ro" {
  lifecycle {
    # do not replace imported shortests passwords
    ignore_changes = [
      length,
      min_lower,
      min_numeric,
      min_special,
      min_upper,
      override_special
    ]
  }

  # Un mot de passe dédié par base, uniquement si des utilisateurs dédiés sont demandés.
  for_each = var.create_dedicated_users ? toset(var.databases) : []

  length           = 32
  special          = true
  override_special = "_"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "scaleway_rdb_user" "this" {
  for_each = var.create_dedicated_users ? toset(var.databases) : []

  instance_id = scaleway_rdb_instance.this.id
  name        = "${each.key}_${terraform.workspace}"
  password    = random_password.user[each.key].result
  is_admin    = false
}

resource "scaleway_rdb_user" "this_ro" {
  for_each = var.create_dedicated_users && var.create_readonly_users ? toset(var.databases) : []

  instance_id = scaleway_rdb_instance.this.id
  name        = "${each.key}_readonly_${terraform.workspace}"
  password    = random_password.user_ro[each.key].result
  is_admin    = false
}

resource "scaleway_rdb_privilege" "this" {
  for_each = var.create_dedicated_users && var.create_readonly_users ? toset(var.databases) : []

  # Contrairement à scaleway_rdb_database/scaleway_rdb_user, le provider Scaleway ne déduit pas la
  # région de scaleway_rdb_privilege depuis le préfixe régional d'instance_id : sans `region`
  # explicite, la ressource retombe sur la région par défaut du provider et échoue dès que
  # `var.region` en diffère (l'UUID d'instance n'existe pas dans cette région-là).
  region        = var.region
  instance_id   = scaleway_rdb_instance.this.id
  user_name     = scaleway_rdb_user.this[each.key].name
  database_name = scaleway_rdb_database.this[each.key].name
  permission    = "all"
}

resource "scaleway_rdb_privilege" "this_ro" {
  for_each = var.create_dedicated_users && var.create_readonly_users ? toset(var.databases) : []

  # Contrairement à scaleway_rdb_database/scaleway_rdb_user, le provider Scaleway ne déduit pas la
  # région de scaleway_rdb_privilege depuis le préfixe régional d'instance_id : sans `region`
  # explicite, la ressource retombe sur la région par défaut du provider et échoue dès que
  # `var.region` en diffère (l'UUID d'instance n'existe pas dans cette région-là).
  region        = var.region
  instance_id   = scaleway_rdb_instance.this.id
  user_name     = scaleway_rdb_user.this_ro[each.key].name
  database_name = scaleway_rdb_database.this[each.key].name
  permission    = "readonly"
}
