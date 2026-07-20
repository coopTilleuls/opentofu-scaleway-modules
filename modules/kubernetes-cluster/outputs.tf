output "cluster_id" {
  description = "ID régional du cluster (format \"<region>/<id>\")."
  value       = scaleway_k8s_cluster.this.id
}

output "cluster_name" {
  description = "Nom du cluster."
  value       = scaleway_k8s_cluster.this.name
}

output "apiserver_url" {
  description = "URL de l'API server du cluster."
  value       = scaleway_k8s_cluster.this.apiserver_url
}

output "token" {
  description = "Token d'authentification admin au cluster."
  value       = scaleway_k8s_cluster.this.kubeconfig[0].token
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Certificat d'autorité du cluster (à fournir au provider kubernetes/helm des couches en aval)."
  value       = scaleway_k8s_cluster.this.kubeconfig[0].cluster_ca_certificate
  sensitive   = true
}

output "pool_ids" {
  description = "Map nom logique du pool => ID du pool."
  value       = { for key, pool in scaleway_k8s_pool.this : key => pool.id }
}
