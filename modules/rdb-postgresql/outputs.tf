output "instance_id" {
  description = "ID de l'instance RDB."
  value       = scaleway_rdb_instance.this.id
}

output "private_ip" {
  description = "Adresse IP privée de l'instance sur le private network rattaché."
  value       = scaleway_rdb_instance.this.private_network[0].ip
}

output "admin_user_name" {
  description = "Nom de l'utilisateur administrateur."
  value       = var.admin_user_name
}

output "admin_password" {
  description = "Mot de passe de l'utilisateur administrateur (fourni par l'appelant ou généré par ce module)."
  value       = local.admin_password
  sensitive   = true
}

output "database_names" {
  description = "Noms des bases de données créées."
  value       = [for db in scaleway_rdb_database.this : db.name]
}

output "database_users" {
  description = <<-EOT
    Map nom_de_base => { username, password }, uniquement renseignée si `create_dedicated_users = true`.
  EOT
  value = {
    for db_name, user in scaleway_rdb_user.this : db_name => {
      username = user.name
      password = random_password.user[db_name].result
    }
  }
  sensitive = true
}
