# Main Terraform configuration for CCPS Portal
# This file is configured per environment using .tfvars files

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

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
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

# Key Vault Access Policy for current service principal (tfAzureDevOps)
# Grants Get, List, and Set permissions (plus additional management permissions)
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

# Log Analytics Workspace for Container Apps (must be created before Container Apps Environment)
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.app_name}-law-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Ensure Microsoft.App provider is registered
resource "null_resource" "register_microsoft_app" {
  provisioner "local-exec" {
    command = "az provider register --namespace Microsoft.App"
  }
}

# Container Apps Environment (shared environment for both apps)
resource "azurerm_container_app_environment" "main" {
  name                       = "${var.app_name}-env-${var.environment}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = var.environment
    Application = var.app_name
  }

  depends_on = [null_resource.register_microsoft_app]
}

# Container App for Backend
resource "azurerm_container_app" "backend" {
  name                         = "${var.app_name}-backend-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = var.container_app_revision_mode

  identity {
    type = "SystemAssigned"
  }

  registry {
    server               = azurerm_container_registry.main.login_server
    username             = azurerm_container_registry.main.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.main.admin_password
  }

  secret {
    name  = "mongodb-uri"
    value = var.mongodb_atlas_connection_string
  }

  secret {
    name  = "jwt-secret"
    value = var.jwt_secret
  }

  template {
    min_replicas = var.backend_min_replicas
    max_replicas = var.backend_max_replicas

    container {
      name   = "backend"
      image  = "${azurerm_container_registry.main.login_server}/${var.app_name}/backend:latest"
      cpu    = var.backend_cpu
      memory = var.backend_memory

      env {
        name  = "NODE_ENV"
        value = var.environment
      }

      env {
        name  = "PORT"
        value = "5500"
      }

      # FRONTEND_URL for CORS - using external URL
      env {
        name  = "FRONTEND_URL"
        value = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
      }

      env {
        name        = "MONGODB_URI"
        secret_name = "mongodb-uri"
      }

      env {
        name        = "JWT_SECRET"
        secret_name = "jwt-secret"
      }

      liveness_probe {
        transport        = "HTTP"
        path             = "/api/health"
        port             = 5500
        interval_seconds = 30
      }

      readiness_probe {
        transport        = "HTTP"
        path             = "/api/health"
        port             = 5500
        interval_seconds = 10
      }
    }
  }

  ingress {
    external_enabled           = true
    target_port                = 5500
    transport                  = "http"
    allow_insecure_connections = false

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
    Component   = "backend"
  }

  depends_on = [
    azurerm_container_app.frontend
  ]
}

# Container App for Frontend
resource "azurerm_container_app" "frontend" {
  name                         = "${var.app_name}-frontend-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = var.container_app_revision_mode

  identity {
    type = "SystemAssigned"
  }

  registry {
    server               = azurerm_container_registry.main.login_server
    username             = azurerm_container_registry.main.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.main.admin_password
  }

  template {
    min_replicas = var.frontend_min_replicas
    max_replicas = var.frontend_max_replicas

    container {
      name   = "frontend"
      image  = "${azurerm_container_registry.main.login_server}/${var.app_name}/frontend:latest"
      cpu    = var.frontend_cpu
      memory = var.frontend_memory

      # Note: VITE_BACKEND_URL must be set during Docker build via build args
      # Vite environment variables are baked into the build at compile time
      # This env var is not used at runtime, but kept for documentation

      liveness_probe {
        transport        = "HTTP"
        path             = "/health"
        port             = 5173
        interval_seconds = 30
      }

      readiness_probe {
        transport        = "HTTP"
        path             = "/health"
        port             = 5173
        interval_seconds = 10
      }
    }
  }

  ingress {
    external_enabled           = true
    target_port                = 5173
    transport                  = "http"
    allow_insecure_connections = false

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
    Component   = "frontend"
  }
}

# Grant backend container app access to Key Vault
resource "azurerm_key_vault_access_policy" "backend" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_container_app.backend.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Grant frontend container app access to Key Vault (if needed in future)
resource "azurerm_key_vault_access_policy" "frontend" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_container_app.frontend.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
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

# Note: Container Apps have built-in service discovery, so no need for null_resource
# Apps in the same environment can communicate using their names as hostnames
# External ingress URLs are automatically available via ingress[0].fqdn