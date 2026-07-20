resource "scaleway_instance_ip" "this" {
  # L'IP publique du bastion est un point d'entrée connu (whitelisté côté firewall, référencé en
  # DNS...) : elle ne doit pas pouvoir être supprimée par un `tofu apply`/`destroy` accidentel.
  lifecycle {
    prevent_destroy = true
  }

  type       = "routed_ipv4"
  project_id = var.project_id
  zone       = var.zone
  tags       = var.tags
}

resource "scaleway_block_volume" "this" {
  count = var.additional_volume_size_gb > 0 ? 1 : 0

  name       = "${var.name}-data"
  size_in_gb = var.additional_volume_size_gb
  iops       = var.additional_volume_iops
  project_id = var.project_id
  zone       = var.zone
  tags       = var.tags
}

resource "scaleway_instance_server" "this" {
  name       = var.name
  type       = var.instance_type
  image      = var.image
  ip_id      = scaleway_instance_ip.this.id
  project_id = var.project_id
  zone       = var.zone
  tags       = var.tags

  additional_volume_ids = var.additional_volume_size_gb > 0 ? [scaleway_block_volume.this[0].id] : []

  user_data = var.user_data

  private_network {
    pn_id = var.private_network_id
  }
}
