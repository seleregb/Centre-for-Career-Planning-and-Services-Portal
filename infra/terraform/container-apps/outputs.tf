# Outputs for Container Apps Terraform configuration

output "container_app_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.name
}

output "container_app_name" {
  description = "Name of the Container App (contains both frontend and backend)"
  value       = azurerm_container_app.main.name
}

output "frontend_url" {
  description = "URL of the frontend (exposed via ingress)"
  value       = "https://${azurerm_container_app.main.ingress[0].fqdn}"
}

output "backend_url_internal" {
  description = "Internal backend URL (localhost:5500, accessible from frontend container in same app)"
  value       = "http://localhost:5500"
}

output "app_identity_principal_id" {
  description = "Principal ID of the Container App managed identity"
  value       = azurerm_user_assigned_identity.app.principal_id
  sensitive   = true
}

