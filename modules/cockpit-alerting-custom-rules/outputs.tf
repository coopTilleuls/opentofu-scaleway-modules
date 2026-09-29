output "rule_group_name" {
  description = "Nom du groupe de règles d'alerte Mimir créé."
  value       = mimir_rule_group_alerting.this.name
}

output "alert_names" {
  description = "Noms des alertes créées (une par règle et par sévérité warning/critical)."
  value       = [for rule in mimir_rule_group_alerting.this.rule : rule.alert]
}
