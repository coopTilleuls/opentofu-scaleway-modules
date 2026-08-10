output "namespace" {
  description = "Namespace créé par le manifest du cluster operator pour RabbitMQ (\"rabbitmq-system\")."
  value       = kubernetes_manifest.cluster_operator["Namespace--rabbitmq-system"].manifest.metadata.name
}
