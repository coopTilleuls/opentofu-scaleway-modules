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

resource "null_resource" "ansible" {
  # Optionnel : exécute un playbook Ansible du repo consommateur contre le bastion, pour la
  # configuration ré-appliquable (comptes utilisateurs, etc.) que cloud-init ne sait gérer qu'une
  # fois, au premier boot.
  count = var.ansible_playbook_path != null ? 1 : 0

  depends_on = [scaleway_instance_server.this]

  triggers = merge(var.ansible_triggers, {
    playbook_hash = filemd5(var.ansible_playbook_path)
    bastion_ip    = scaleway_instance_ip.this.address
  })

  connection {
    type  = "ssh"
    user  = var.ansible_ssh_user
    host  = scaleway_instance_ip.this.address
    agent = true
  }

  # S'assure que cloud-init (paquets, montage du volume additionnel...) a terminé avant qu'Ansible
  # ne prenne le relais.
  provisioner "remote-exec" {
    inline = ["cloud-init status --wait"]
  }

  provisioner "local-exec" {
    command = join(" ", compact([
      "ansible-playbook",
      "-i '${scaleway_instance_ip.this.address},'",
      "-u ${var.ansible_ssh_user}",
      var.ansible_extra_vars_file != null ? "-e @${var.ansible_extra_vars_file}" : "",
      var.ansible_playbook_path,
    ]))
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
}
