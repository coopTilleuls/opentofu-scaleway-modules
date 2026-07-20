output "vpc_id" {
  description = "ID du VPC."
  value       = scaleway_vpc.this.id
}

output "private_network_ids" {
  description = "Map nom logique du private network => ID du private network."
  value       = { for key, pn in scaleway_vpc_private_network.this : key => pn.id }
}

output "public_gateway_ids" {
  description = "Map \"clé_gateway/zone\" => ID de la public gateway."
  value       = { for key, gw in scaleway_vpc_public_gateway.this : key => gw.id }
}

output "public_gateway_ips" {
  description = "Map \"clé_gateway/zone\" => adresse IP flexible publique de la gateway."
  value       = { for key, ip in scaleway_flexible_ip.gateway : key => ip.address }
}

output "gateway_network_ids" {
  description = "Map \"clé_gateway/zone\" => ID de l'attachement gateway/private network."
  value       = { for key, gn in scaleway_vpc_gateway_network.this : key => gn.id }
}

output "gateway_private_ips" {
  description = "Map \"clé_gateway/zone\" => IP IPAM réservée pour la gateway sur son private network."
  value       = { for key, ip in scaleway_ipam_ip.gateway : key => split("/", ip.address)[0] }
}

output "reserved_lb_ip_ids" {
  description = "Map \"clé_lb/zone\" => ID de l'IP flexible de load-balancer réservée."
  value       = { for key, ip in scaleway_lb_ip.this : key => ip.id }
}

output "reserved_lb_ips" {
  description = "Map \"clé_lb/zone\" => adresse de l'IP flexible de load-balancer réservée."
  value       = { for key, ip in scaleway_lb_ip.this : key => ip.ip_address }
}
