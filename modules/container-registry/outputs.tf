output "namespace_id" {
  description = "ID du namespace de registry."
  value       = scaleway_registry_namespace.this.id
}

output "endpoint" {
  description = "Endpoint Docker du namespace."
  value       = scaleway_registry_namespace.this.endpoint
}
