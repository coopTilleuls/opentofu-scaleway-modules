output "bucket_id" {
  description = "ID (Terraform) du bucket."
  value       = scaleway_object_bucket.this.id
}

output "bucket_name" {
  description = "Nom du bucket."
  value       = scaleway_object_bucket.this.name
}

output "bucket_endpoint" {
  description = "Endpoint S3 du bucket."
  value       = scaleway_object_bucket.this.endpoint
}
