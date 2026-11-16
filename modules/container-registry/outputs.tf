output "namespace_id" {
  description = "ID du namespace de registry."
  value       = scaleway_registry_namespace.this.id
}

output "endpoint" {
  description = "Endpoint Docker du namespace."
  value       = scaleway_registry_namespace.this.endpoint
}

output "retention_job_definition_id" {
  description = "ID du Serverless Job de purge des tags, si `retention` est renseigné (sinon `null`)."
  value       = local.retention_enabled ? scaleway_job_definition.retention[0].id : null
}
