# Main Terraform configuration for CCPS Portal
# This file is configured per environment using .tfvars files

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Backend configuration is provided via -backend-config during init
    # resource_group_name  = "rg-terraform-state"
    # storage_account_name = "stterraformstate"
    # container_name       = "tfstate"
    # key                  = "terraform.tfstate"
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = var.prevent_resource_group_deletion
    }
  }
}

provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Get subscription information
data "azurerm_subscription" "current" {}

data "azuread_service_principal" "current_sp" {
  display_name = "tfAzureDevOps"
}

# Role Assignments for Subscription
resource "azurerm_role_assignment" "subscription" {
  for_each             = toset(var.subscription_required_role_assignments)
  scope                = data.azurerm_subscription.current.id
  role_definition_name = each.value
  principal_id         = data.azuread_service_principal.current_sp.object_id
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Role Assignments for Resource Group
resource "azurerm_role_assignment" "resource_group" {
  for_each             = toset(var.resource_group_required_role_assignments)
  scope                = azurerm_resource_group.main.id
  role_definition_name = each.value
  principal_id         = data.azuread_service_principal.current_sp.object_id
  depends_on           = [azurerm_resource_group.main]
}

# General-purpose v2 Storage Account
resource "azurerm_storage_account" "main" {
  name                            = "${substr(replace(var.app_name, "-", ""), 0, 18)}st${var.environment}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_account_replication_type
  account_kind                    = var.storage_account_kind
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = var.storage_shared_access_key_enabled

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Role Assignments for Storage Account
resource "azurerm_role_assignment" "storage_account" {
  for_each             = toset(var.storage_required_role_assignments)
  scope                = azurerm_storage_account.main.id
  role_definition_name = each.value
  principal_id         = data.azuread_service_principal.current_sp.object_id
  depends_on           = [azurerm_storage_account.main]
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.app_name, "-", "")}acr${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku           # Basic, Standard, Premium
  admin_enabled       = var.acr_admin_enabled # true or false

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Role Assignments for Azure Container Registry
resource "azurerm_role_assignment" "acr" {
  for_each             = toset(var.acr_required_role_assignments)
  scope                = azurerm_container_registry.main.id
  role_definition_name = each.value
  principal_id         = data.azuread_service_principal.current_sp.object_id
  depends_on           = [azurerm_container_registry.main]
}

# Key Vault for secrets management
resource "azurerm_key_vault" "main" {
  name                = "${var.app_name}-kv-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  enabled_for_disk_encryption     = true

  # Production-specific settings
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  purge_protection_enabled   = var.key_vault_purge_protection_enabled

  # Network ACLs for production
  dynamic "network_acls" {
    for_each = var.key_vault_network_acls != null ? [1] : []
    content {
      default_action = var.key_vault_network_acls.default_action
      bypass         = var.key_vault_network_acls.bypass
      ip_rules       = var.key_vault_network_acls.ip_rules
    }
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Key Vault Access Policy for current user/service principal
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.current_sp.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]
}

# Role Assignments for Key Vault
resource "azurerm_key_vault_access_policy" "key_vault" {
  for_each     = toset(var.key_vault_required_role_assignments)
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.current_sp.object_id
  depends_on   = [azurerm_key_vault.main]
}

# App Service Plan for Backend
resource "azurerm_service_plan" "backend" {
  name                = "${var.app_name}-asp-backend-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.backend_sku

  tags = {
    Environment = var.environment
    Application = var.app_name
    Component   = "backend"
  }
}

# App Service for Backend Container
resource "azurerm_linux_web_app" "backend" {
  name                = "${var.app_name}-backend-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.backend.id

  site_config {
    always_on     = var.backend_always_on
    http2_enabled = var.backend_http2_enabled

    # Container configuration
    application_stack {
      docker_image_name   = "${var.app_name}/backend:latest"
      docker_registry_url = "https://${azurerm_container_registry.main.login_server}"
    }

    # Security settings
    minimum_tls_version = var.backend_minimum_tls_version
    ftps_state          = var.backend_ftps_state
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.main.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.main.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.main.admin_password
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "NODE_ENV"                            = var.environment
    "PORT"                                = "3000"
    "KEY_VAULT_NAME"                      = azurerm_key_vault.main.name

    # CORS configuration - will be updated after frontend is created (see null_resource below)
    # "FRONTEND_URL" = "https://${azurerm_linux_web_app.frontend.default_hostname}"

    # Reference MongoDB connection string from Key Vault
    "MONGODB_URI" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.mongodb_connection_string.id})"
    "JWT_SECRET"  = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.jwt_secret.id})"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
    Component   = "backend"
  }

  lifecycle {
    ignore_changes = [
      app_settings["FRONTEND_URL"]
    ]
  }
}

# Grant backend app service access to Key Vault
resource "azurerm_key_vault_access_policy" "backend" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.backend.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# App Service Plan for Frontend
resource "azurerm_service_plan" "frontend" {
  name                = "${var.app_name}-asp-frontend-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.frontend_sku

  tags = {
    Environment = var.environment
    Application = var.app_name
    Component   = "frontend"
  }
}

# App Service for Frontend Container
resource "azurerm_linux_web_app" "frontend" {
  name                = "${var.app_name}-frontend-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.frontend.id

  site_config {
    always_on     = var.frontend_always_on
    http2_enabled = var.frontend_http2_enabled

    # Container configuration
    application_stack {
      docker_image_name   = "${var.app_name}/frontend:latest"
      docker_registry_url = "https://${azurerm_container_registry.main.login_server}"
    }

    # Security settings
    minimum_tls_version = var.frontend_minimum_tls_version
    ftps_state          = var.frontend_ftps_state
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.main.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.main.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.main.admin_password
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "80"

    # Backend API URL - will be updated after backend is created (see null_resource below)
    # Note: Vite requires this at build time, so it should be set during Docker build
    # This is provided for runtime configuration if needed
    # "VITE_API_URL" = "https://${azurerm_linux_web_app.backend.default_hostname}"
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
    Component   = "frontend"
  }

  lifecycle {
    ignore_changes = [
      app_settings["VITE_API_URL"]
    ]
  }
}

# Key Vault Secret for MongoDB Atlas Connection String
resource "azurerm_key_vault_secret" "mongodb_connection_string" {
  name         = "MongoDBAtlasConnectionString"
  value        = var.mongodb_atlas_connection_string
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Key Vault Secret for JWT Secret
resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "JWTSecret"
  value        = var.jwt_secret
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Update app settings after both apps are created to set cross-references
# This breaks the circular dependency by updating settings after resources exist
resource "null_resource" "update_backend_cors" {
  depends_on = [
    azurerm_linux_web_app.backend,
    azurerm_linux_web_app.frontend
  ]

  triggers = {
    backend_id   = azurerm_linux_web_app.backend.id
    frontend_id  = azurerm_linux_web_app.frontend.id
    frontend_url = "https://${azurerm_linux_web_app.frontend.default_hostname}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      az webapp config appsettings set \
        --name ${azurerm_linux_web_app.backend.name} \
        --resource-group ${azurerm_resource_group.main.name} \
        --settings FRONTEND_URL="https://${azurerm_linux_web_app.frontend.default_hostname}" \
        --output none
    EOT
  }
}

resource "null_resource" "update_frontend_api_url" {
  depends_on = [
    azurerm_linux_web_app.backend,
    azurerm_linux_web_app.frontend
  ]

  triggers = {
    backend_id  = azurerm_linux_web_app.backend.id
    frontend_id = azurerm_linux_web_app.frontend.id
    backend_url = "https://${azurerm_linux_web_app.backend.default_hostname}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      az webapp config appsettings set \
        --name ${azurerm_linux_web_app.frontend.name} \
        --resource-group ${azurerm_resource_group.main.name} \
        --settings VITE_API_URL="https://${azurerm_linux_web_app.backend.default_hostname}" \
        --output none
    EOT
  }
}