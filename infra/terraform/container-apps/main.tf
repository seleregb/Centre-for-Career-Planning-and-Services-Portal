# Container Apps Terraform configuration for CCPS Portal
# This file deploys Container Apps Environment and Container Apps
# Note: ACR must be deployed first and images must be pushed before deploying this

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
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Reference existing Resource Group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Reference existing Azure Container Registry
data "azurerm_container_registry" "main" {
  name                = "${replace(var.app_name, "-", "")}acr${var.environment}"
  resource_group_name = var.resource_group_name
}

# Reference existing Key Vault
data "azurerm_key_vault" "main" {
  name                = "${var.app_name}-kv-${var.environment}"
  resource_group_name = var.resource_group_name
}

# Log Analytics Workspace for Container Apps (must be created before Container Apps Environment)
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.app_name}-law-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
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
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = var.environment
    Application = var.app_name
  }

  depends_on = [null_resource.register_microsoft_app]
}

# Local values to construct URLs and break circular dependency
locals {
  # Construct frontend URL using environment's default domain pattern
  # This breaks the circular dependency by not directly referencing frontend resource
  # Azure Container Apps FQDN pattern: <app-name>.<default-domain>
  frontend_fqdn = "${var.app_name}-frontend-${var.environment}.${replace(azurerm_container_app_environment.main.default_domain, "*.", "")}"

  # Construct backend URL using environment's default domain pattern
  backend_fqdn = "${var.app_name}-backend-${var.environment}.${replace(azurerm_container_app_environment.main.default_domain, "*.", "")}"
}

data "azurerm_key_vault_secret" "mongodb_atlas_connection_string" {
  name         = "MongoDBAtlasConnectionString"
  key_vault_id = data.azurerm_key_vault.main.id
}

data "azurerm_key_vault_secret" "jwt_secret" {
  name         = "JWTSecret"
  key_vault_id = data.azurerm_key_vault.main.id
}

# Container App for Backend
resource "azurerm_container_app" "backend" {
  name                         = "${var.app_name}-backend-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = data.azurerm_resource_group.main.name
  revision_mode                = var.container_app_revision_mode

  identity {
    type = "SystemAssigned"
  }

  registry {
    server               = data.azurerm_container_registry.main.login_server
    username             = data.azurerm_container_registry.main.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = data.azurerm_container_registry.main.admin_password
  }

  secret {
    name                = "mongodb-uri"
    key_vault_secret_id = data.azurerm_key_vault_secret.mongodb_atlas_connection_string.id
  }

  secret {
    name                = "jwt-secret"
    key_vault_secret_id = data.azurerm_key_vault_secret.jwt_secret.id
  }

  template {
    min_replicas = var.backend_min_replicas
    max_replicas = var.backend_max_replicas

    container {
      name   = "backend"
      image  = "${data.azurerm_container_registry.main.login_server}/${var.app_name}/backend:latest"
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

      # FRONTEND_URL for CORS - using constructed URL to break circular dependency
      env {
        name  = "FRONTEND_URL"
        value = "https://${local.frontend_fqdn}"
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
}

# Container App for Frontend
resource "azurerm_container_app" "frontend" {
  name                         = "${var.app_name}-frontend-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = data.azurerm_resource_group.main.name
  revision_mode                = var.container_app_revision_mode

  identity {
    type = "SystemAssigned"
  }

  registry {
    server               = data.azurerm_container_registry.main.login_server
    username             = data.azurerm_container_registry.main.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = data.azurerm_container_registry.main.admin_password
  }

  template {
    min_replicas = var.frontend_min_replicas
    max_replicas = var.frontend_max_replicas

    container {
      name   = "frontend"
      image  = "${data.azurerm_container_registry.main.login_server}/${var.app_name}/frontend:latest"
      cpu    = var.frontend_cpu
      memory = var.frontend_memory

      # BACKEND_URL is used at container startup to generate config.json
      # The Dockerfile entrypoint script reads this env var and creates config.json
      # Using constructed URL to break circular dependency
      env {
        name  = "BACKEND_URL"
        value = "https://${local.backend_fqdn}"
      }

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
  key_vault_id = data.azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_container_app.backend.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Grant frontend container app access to Key Vault (if needed in future)
resource "azurerm_key_vault_access_policy" "frontend" {
  key_vault_id = data.azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_container_app.frontend.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Note: Container Apps have built-in service discovery, so no need for null_resource
# Apps in the same environment can communicate using their names as hostnames
# External ingress URLs are automatically available via ingress[0].fqdn

