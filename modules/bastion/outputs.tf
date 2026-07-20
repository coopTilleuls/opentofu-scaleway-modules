output "instance_id" {
  description = "ID de l'instance bastion."
  value       = scaleway_instance_server.this.id
}

output "public_ip" {
  description = "Adresse IP publique du bastion."
  value       = scaleway_instance_ip.this.address
}

output "private_ip" {
  description = "Adresse IP privée du bastion sur le private network rattaché."
  value       = scaleway_instance_server.this.private_ips[0].address
}
