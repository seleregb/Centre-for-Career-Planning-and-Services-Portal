# Bootstrap Terraform Configuration
# This creates service principals and assigns required roles for Terraform deployments
#
# IMPORTANT: This requires manual bootstrap permissions (see README.md)
# After running this, you can use the created service principals for future deployments

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Get subscription information
data "azurerm_subscription" "current" {}

# Get the storage account for Terraform state backend
data "azurerm_storage_account" "terraform_state" {
  name                = var.terraform_state_storage_account_name
  resource_group_name = var.terraform_state_resource_group_name
}

# Create Azure AD Application for Terraform Service Principal
resource "azuread_application" "terraform" {
  display_name = var.service_principal_name
  description  = "Service principal for Terraform deployments of CCPS Portal"
  
  # Optional: Add required resource access
  # required_resource_access {
  #   resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
  #   ...
  # }

  tags = [
    "terraform",
    "ccps-portal",
    var.environment
  ]
}

# Create Service Principal
resource "azuread_service_principal" "terraform" {
  application_id               = azuread_application.terraform.application_id
  app_role_assignment_required = false
  description                  = "Service principal for Terraform deployments"

  tags = [
    "terraform",
    "ccps-portal",
    var.environment
  ]
}

# Create Service Principal Password
resource "azuread_service_principal_password" "terraform" {
  service_principal_id = azuread_service_principal.terraform.id
  
  # Password display name with timestamp
  display_name = "${var.service_principal_name}-password-${formatdate("YYYY-MM-DD", timestamp())}"
  
  # Set end date for password rotation (optional)
  # If password_rotation_days > 0, set end date; otherwise password doesn't expire
  end_date = var.password_rotation_days > 0 ? timeadd(timestamp(), "${var.password_rotation_days * 24}h") : null
  
  lifecycle {
    ignore_changes = [
      display_name
    ]
  }
}

# Assign Contributor role at subscription level
resource "azurerm_role_assignment" "contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.terraform.object_id
  
  description = "Contributor role for Terraform service principal"
}

# Assign User Access Administrator role (for Key Vault access policies)
resource "azurerm_role_assignment" "user_access_admin" {
  count                = var.assign_user_access_admin ? 1 : 0
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.terraform.object_id
  
  description = "User Access Administrator role for managing Key Vault access policies"
}

# Assign Storage Blob Data Contributor for Terraform state backend
resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = data.azurerm_storage_account.terraform_state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.terraform.object_id
  
  description = "Storage Blob Data Contributor for Terraform state access"
}

# Optionally: Assign roles at resource group level (if deploying to specific resource groups)
resource "azurerm_role_assignment" "contributor_rg" {
  for_each             = var.resource_group_scopes
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${each.value}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.terraform.object_id
  
  description = "Contributor role for resource group: ${each.value}"
}

