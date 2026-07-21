output "namespace" {
  description = "Namespace flux-system créé par le module."
  value       = kubernetes_namespace_v1.flux_system.metadata[0].name
}

output "deploy_key_public" {
  description = <<-EOT
    Clé publique SSH (format OpenSSH) générée pour l'accès de Flux au repo Git. À enregistrer
    manuellement comme deploy key (lecture seule) chez l'hébergeur Git : ce module ne gère pas la
    création de la deploy key elle-même (pas de provider `github`/`gitlab`), comme dans les repos
    d'origine.
  EOT
  value       = tls_private_key.flux_system.public_key_openssh
}

output "flux_installed" {
  description = "true si les controllers Flux ont été installés (ou l'étaient déjà) au dernier apply."
  value       = length(data.kubernetes_resources.flux_deployment.objects) > 0 || length(null_resource.flux_install) > 0
}
