# Outputs for Container Apps Terraform configuration

output "container_app_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.name
}

output "backend_container_app_name" {
  description = "Name of the backend Container App"
  value       = azurerm_container_app.backend.name
}

output "backend_container_app_url" {
  description = "URL of the backend Container App"
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

output "frontend_container_app_name" {
  description = "Name of the frontend Container App"
  value       = azurerm_container_app.frontend.name
}

output "frontend_container_app_url" {
  description = "URL of the frontend Container App"
  value       = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
}

output "backend_identity_principal_id" {
  description = "Principal ID of the backend Container App managed identity"
  value       = azurerm_container_app.backend.identity[0].principal_id
  sensitive   = true
}

output "frontend_identity_principal_id" {
  description = "Principal ID of the frontend Container App managed identity"
  value       = azurerm_container_app.frontend.identity[0].principal_id
  sensitive   = true
}

