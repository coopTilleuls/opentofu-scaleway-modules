output "rule_group_name" {
  description = "Nom du groupe de règles Loki créé."
  value       = loki_rule_group_alerting.this.name
}

output "alert_names" {
  description = "Noms des alertes créées."
  value       = [for rule in local.group.rules : replace("${local.group.name} - ${rule.alert}", "/[^a-zA-Z0-9-_.]/", "_")]
}
