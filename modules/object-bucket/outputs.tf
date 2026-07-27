output "bucket_id" {
  description = "ID (Terraform) du bucket."
  value       = local.bucket.id
}

output "bucket_name" {
  description = "Nom du bucket."
  value       = local.bucket.name
}

output "bucket_endpoint" {
  description = "Endpoint S3 du bucket."
  value       = local.bucket.endpoint
}
