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

output "dashboards" {
  description = <<-EOT
    Dashboards Grafana (JSON) fournis par le module, à importer dans le Grafana Cockpit
    (Dashboards > New > Import) ou à provisionner par l'appelant (ex. `grafana_dashboard`).
    Les sources de données sont des variables du dashboard (pas d'UID en dur) : ils sont portables
    d'un projet à l'autre. Voir le README, section « Dashboards ».
  EOT
  value = {
    bastion = file("${path.module}/dashboards/bastion.json")
  }
}
