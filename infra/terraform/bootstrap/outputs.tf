# Outputs for bootstrap Terraform configuration

output "service_principal_id" {
  description = "Object ID of the service principal"
  value       = azuread_service_principal.terraform.object_id
}

output "service_principal_client_id" {
  description = "Application (client) ID of the service principal"
  value       = azuread_service_principal.terraform.application_id
}

output "service_principal_client_secret" {
  description = "Client secret (password) for the service principal - STORE THIS SECURELY"
  value       = azuread_service_principal_password.terraform.value
  sensitive   = true
}

output "service_principal_tenant_id" {
  description = "Azure AD tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  description = "Azure subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

output "azure_devops_service_connection_config" {
  description = "Configuration values for Azure DevOps service connection"
  value = {
    service_principal_client_id     = azuread_service_principal.terraform.application_id
    service_principal_client_secret = azuread_service_principal_password.terraform.value
    tenant_id                       = data.azurerm_client_config.current.tenant_id
    subscription_id                 = data.azurerm_subscription.current.subscription_id
    subscription_name               = data.azurerm_subscription.current.display_name
  }
  sensitive = true
}

# Output formatted commands for manual verification
output "verify_commands" {
  description = "Commands to verify the service principal and permissions"
  value = <<-EOT
    # Verify service principal exists
    az ad sp show --id ${azuread_service_principal.terraform.application_id}
    
    # List role assignments for the service principal
    az role assignment list --assignee ${azuread_service_principal.terraform.application_id} --all
    
    # Test login with service principal
    az login --service-principal \
      --username ${azuread_service_principal.terraform.application_id} \
      --password <SECRET_FROM_OUTPUT> \
      --tenant ${data.azurerm_client_config.current.tenant_id}
  EOT
}

