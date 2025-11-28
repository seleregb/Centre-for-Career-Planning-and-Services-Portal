# Outputs for Database Terraform configuration

output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.main.name
}

# PostgreSQL Database Outputs
output "postgresql_server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  value       = var.postgresql_server_name != "" ? azurerm_postgresql_flexible_server.main[0].name : null
}

output "postgresql_server_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server"
  value       = var.postgresql_server_name != "" ? azurerm_postgresql_flexible_server.main[0].fqdn : null
}

output "postgresql_database_name" {
  description = "Name of the PostgreSQL database"
  value       = var.postgresql_server_name != "" ? azurerm_postgresql_flexible_server_database.main[0].name : null
}

output "postgresql_location" {
  description = "Location of the PostgreSQL Flexible Server"
  value       = var.postgresql_server_name != "" ? azurerm_postgresql_flexible_server.main[0].location : null
}

# MySQL Database Outputs
output "mysql_server_name" {
  description = "Name of the MySQL Flexible Server"
  value       = var.mysql_server_name != "" ? azurerm_mysql_flexible_server.main[0].name : null
}

output "mysql_server_fqdn" {
  description = "FQDN of the MySQL Flexible Server"
  value       = var.mysql_server_name != "" ? azurerm_mysql_flexible_server.main[0].fqdn : null
}

output "mysql_database_name" {
  description = "Name of the MySQL database"
  value       = var.mysql_server_name != "" ? azurerm_mysql_flexible_database.main[0].name : null
}

output "mysql_location" {
  description = "Location of the MySQL Flexible Server"
  value       = var.mysql_server_name != "" ? azurerm_mysql_flexible_server.main[0].location : null
}

# Database Connection String Secrets in Key Vault
output "postgresql_connection_string_secret_name" {
  description = "Name of the Key Vault secret containing PostgreSQL connection string"
  value       = var.postgresql_server_name != "" ? azurerm_key_vault_secret.postgresql_connection_string[0].name : null
}

output "mysql_connection_string_secret_name" {
  description = "Name of the Key Vault secret containing MySQL connection string"
  value       = var.mysql_server_name != "" ? azurerm_key_vault_secret.mysql_connection_string[0].name : null
}

