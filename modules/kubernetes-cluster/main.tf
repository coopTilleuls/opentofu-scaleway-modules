resource "scaleway_k8s_cluster" "this" {
  # prevent_destroy est volontairement figé en dur (et non piloté par une variable) : la valeur
  # de `lifecycle` doit être une constante littérale en Terraform/OpenTofu, elle ne peut pas
  # dépendre d'une variable. Un cluster de production ne doit jamais pouvoir être détruit par
  # un `tofu apply` accidentel ; le déprotéger nécessite une modification volontaire de ce fichier.
  lifecycle {
    prevent_destroy = true
  }

  name       = var.name
  project_id = var.project_id
  region     = var.region

  type                        = var.type
  version                     = var.version_prefix
  cni                         = var.cni
  delete_additional_resources = var.delete_additional_resources
  tags                        = var.tags

  private_network_id = var.private_network_id

  autoscaler_config {
    scale_down_delay_after_add       = var.autoscaler_config.scale_down_delay_after_add
    scale_down_unneeded_time         = var.autoscaler_config.scale_down_unneeded_time
    estimator                        = var.autoscaler_config.estimator
    expander                         = var.autoscaler_config.expander
    ignore_daemonsets_utilization    = var.autoscaler_config.ignore_daemonsets_utilization
    balance_similar_node_groups      = var.autoscaler_config.balance_similar_node_groups
    scale_down_utilization_threshold = var.autoscaler_config.scale_down_utilization_threshold
  }

  dynamic "auto_upgrade" {
    # Un bloc `auto_upgrade { enable = false }` reste valide côté API : on le désactive donc
    # simplement via son propre attribut plutôt que d'omettre le bloc.
    for_each = [var.auto_upgrade]
    content {
      enable                        = auto_upgrade.value.enable
      maintenance_window_day        = auto_upgrade.value.maintenance_window_day
      maintenance_window_start_hour = auto_upgrade.value.maintenance_window_start_hour
    }
  }

  dynamic "open_id_connect_config" {
    for_each = var.open_id_connect_config != null ? [var.open_id_connect_config] : []
    content {
      issuer_url      = open_id_connect_config.value.issuer_url
      client_id       = open_id_connect_config.value.client_id
      username_claim  = open_id_connect_config.value.username_claim
      username_prefix = open_id_connect_config.value.username_prefix
      groups_claim    = open_id_connect_config.value.groups_claim
      groups_prefix   = open_id_connect_config.value.groups_prefix
      required_claim  = open_id_connect_config.value.required_claim
    }
  }
}

resource "time_sleep" "wait_after_network" {
  # Laisse le temps à la gateway réseau de propager sa route par défaut avant que les nodes
  # ne tentent de sortir sur Internet (image container, join du cluster, etc.). Reproduit un
  # comportement observé et contourné manuellement sur les projets existants.
  depends_on      = [scaleway_k8s_cluster.this, var.network_dependencies]
  create_duration = "${var.wait_after_network_seconds}s"
}

locals {
  # Aplatit chaque famille de pool sur ses tailles et sur var.zones (une scaleway_k8s_pool par
  # combinaison famille × taille × zone). `slug` sert de clé for_each : il ne doit PAS contenir le
  # hash de root_volume_size_in_gb (voir plus bas), sous peine de casser le create_before_destroy
  # (Terraform traiterait un changement de taille de volume comme un add+destroy non ordonné sur
  # deux adresses de resource distinctes, plutôt qu'un remplacement de la même adresse).
  zonal_sized_pools = flatten([
    for pool in var.pools : [
      for size in pool.sizes : [
        for zone in var.zones : {
          slug                   = "${pool.name}-${lower(replace(size.node_type, "-", ""))}-${regex("[0-9]+$", zone)}"
          zone                   = zone
          node_type              = size.node_type
          max_per_zone           = size.max_per_zone
          root_volume_size_in_gb = size.root_volume_size_in_gb
          tags                   = pool.tags
          labels                 = pool.labels
          taints                 = pool.taints
        }
      ]
    ]
  ])
}

resource "scaleway_k8s_pool" "this" {
  for_each = { for p in local.zonal_sized_pools : p.slug => p }

  depends_on = [time_sleep.wait_after_network]

  lifecycle {
    # Un pool est recréé avant d'être détruit lors d'un changement structurant (ex: node_type),
    # pour ne jamais se retrouver sans capacité pendant la bascule.
    create_before_destroy = true
  }

  cluster_id = scaleway_k8s_cluster.this.id
  # Le hash du seul attribut ForceNew encore variable ici (root_volume_size_in_gb) garantit que
  # l'ancien et le nouveau pool n'ont jamais le même nom pendant la fenêtre de
  # create_before_destroy, alors que `slug` (sans hash, voir le local ci-dessus) reste stable.
  name = "${each.value.slug}-${substr(md5("${each.value.root_volume_size_in_gb}"), 0, 4)}"
  zone = each.value.zone

  node_type = each.value.node_type

  # Toujours 0 : l'autoscaler (toujours actif ci-dessous) pilote seul la taille réelle du pool
  # depuis sa création ; un size/min_size non nul au provisioning déroute son calcul du plancher.
  size        = 0
  min_size    = 0
  max_size    = each.value.max_per_zone
  autoscaling = true
  autohealing = true

  container_runtime      = "containerd"
  root_volume_size_in_gb = each.value.root_volume_size_in_gb
  public_ip_disabled     = true

  # "scw-compute-image" (provisionnement plus rapide des nodes) est systématique sur les deux
  # repos sources, d'où son ajout en dur ici plutôt que via var.tags.
  tags = concat(
    ["zone=${each.value.zone}", "scw-compute-image"],
    var.tags,
    each.value.tags
  )

  # `taints` est un bloc répétable côté provider Scaleway (et non un argument de type liste).
  dynamic "taints" {
    for_each = each.value.taints
    content {
      key    = taints.value.key
      value  = taints.value.value
      effect = taints.value.effect
    }
  }

  labels = each.value.labels

  upgrade_policy {
    max_surge       = var.pool_upgrade_policy.max_surge
    max_unavailable = var.pool_upgrade_policy.max_unavailable
  }
}

resource "null_resource" "kubeconfig" {
  count = var.install_kubeconfig ? 1 : 0

  # Attend que les pools existent : sans cette dépendance, rien n'empêche `scw k8s kubeconfig
  # install` de s'exécuter en parallèle de leur création côté API.
  depends_on = [scaleway_k8s_pool.this]

  triggers = {
    cluster_id = scaleway_k8s_cluster.this.id
  }

  provisioner "local-exec" {
    # scaleway_k8s_cluster.this.id est au format "<region>/<uuid>" ; la CLI `scw` attend l'UUID
    # seul, d'où le retrait du préfixe régional.
    command = "scw k8s kubeconfig install ${regex("(?:.*/)?(.*)", scaleway_k8s_cluster.this.id)[0]}"
  }
}
