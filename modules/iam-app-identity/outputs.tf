output "application_id" {
  description = "ID de l'application IAM."
  value       = scaleway_iam_application.this.id
}

output "policy_id" {
  description = "ID de la policy IAM."
  value       = scaleway_iam_policy.this.id
}

output "access_key" {
  description = "Access key de la clé API générée."
  value       = scaleway_iam_api_key.this.access_key
}

output "secret_key" {
  description = "Secret key de la clé API générée."
  value       = scaleway_iam_api_key.this.secret_key
  sensitive   = true
}

output "secret_id" {
  description = "ID du secret Secret Manager créé, si `create_secret = true` (sinon `null`)."
  value       = var.create_secret ? scaleway_secret.this[0].id : null
}
