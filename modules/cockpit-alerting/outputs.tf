output "custom_rule_group_names" {
  description = "Noms des groupes de règles d'alerte Mimir créés (préconfigurées + custom)."
  value       = [for group in mimir_rule_group_alerting.custom_rules : group.name]
}

output "metrics_source_url" {
  description = "URL de la source Cockpit de métriques."
  value       = scaleway_cockpit_source.metrics.url
}

output "logs_source_url" {
  description = "URL de la source Cockpit de logs."
  value       = scaleway_cockpit_source.logs.url
}

output "traces_source_url" {
  description = "URL de la source Cockpit de traces."
  value       = scaleway_cockpit_source.traces.url
}
