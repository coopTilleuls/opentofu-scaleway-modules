#output "application_id" {
#  description = "ID de l'application IAM créée pour la lecture du Secret Manager."
#  value       = scaleway_iam_application.secret_manager.id
#}
#
#output "policy_id" {
#  description = "ID de la policy IAM donnant l'accès en lecture seule au Secret Manager."
#  value       = scaleway_iam_policy.secret_read_only.id
#}
#
#output "namespace_secret_ids" {
#  description = "ID du secret Secret Manager créé pour chaque namespace (clé = nom du namespace)."
#  value       = { for ns, secret in scaleway_secret.namespace : ns => secret.id }
#}
