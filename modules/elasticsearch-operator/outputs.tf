output "namespace" {
  description = "Namespace créé par le manifest operator.yaml pour l'operator ECK (\"elastic-system\")."
  value       = kubernetes_manifest.operator["Namespace--elastic-system"].manifest.metadata.name
}
