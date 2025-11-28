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

# Virtual Network for Container Apps
resource "azurerm_virtual_network" "container_apps" {
  name                = "${var.app_name}-container-apps-vnet-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = ["10.2.0.0/16"]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Subnet for Container Apps Environment (dedicated subnet for VNet integration)
resource "azurerm_subnet" "container_apps" {
  name                 = "${var.app_name}-container-apps-subnet-${var.environment}"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.container_apps.name
  address_prefixes     = ["10.2.0.0/23"]

  delegation {
    name = "delegation-container-apps"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Reference MySQL VNet (if it exists)
data "azurerm_virtual_network" "mysql" {
  count               = var.mysql_vnet_name != "" ? 1 : 0
  name                = var.mysql_vnet_name
  resource_group_name = var.resource_group_name
}

# Reference PostgreSQL VNet (if it exists)
data "azurerm_virtual_network" "postgresql" {
  count               = var.postgresql_vnet_name != "" ? 1 : 0
  name                = var.postgresql_vnet_name
  resource_group_name = var.resource_group_name
}

# VNet Peering: Container Apps -> MySQL VNet
resource "azurerm_virtual_network_peering" "container_apps_to_mysql" {
  count                        = var.mysql_vnet_name != "" ? 1 : 0
  name                         = "${var.app_name}-container-apps-to-mysql-${var.environment}"
  resource_group_name          = data.azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.container_apps.name
  remote_virtual_network_id    = data.azurerm_virtual_network.mysql[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet Peering: MySQL VNet -> Container Apps
resource "azurerm_virtual_network_peering" "mysql_to_container_apps" {
  count                        = var.mysql_vnet_name != "" ? 1 : 0
  name                         = "${var.app_name}-mysql-to-container-apps-${var.environment}"
  resource_group_name          = data.azurerm_resource_group.main.name
  virtual_network_name         = data.azurerm_virtual_network.mysql[0].name
  remote_virtual_network_id    = azurerm_virtual_network.container_apps.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet Peering: Container Apps -> PostgreSQL VNet
resource "azurerm_virtual_network_peering" "container_apps_to_postgresql" {
  count                        = var.postgresql_vnet_name != "" ? 1 : 0
  name                         = "${var.app_name}-container-apps-to-postgresql-${var.environment}"
  resource_group_name          = data.azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.container_apps.name
  remote_virtual_network_id    = data.azurerm_virtual_network.postgresql[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet Peering: PostgreSQL VNet -> Container Apps
resource "azurerm_virtual_network_peering" "postgresql_to_container_apps" {
  count                        = var.postgresql_vnet_name != "" ? 1 : 0
  name                         = "${var.app_name}-postgresql-to-container-apps-${var.environment}"
  resource_group_name          = data.azurerm_resource_group.main.name
  virtual_network_name         = data.azurerm_virtual_network.postgresql[0].name
  remote_virtual_network_id    = azurerm_virtual_network.container_apps.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Reference MySQL Private DNS Zone (if it exists)
data "azurerm_private_dns_zone" "mysql" {
  count               = var.mysql_private_dns_zone_name != "" ? 1 : 0
  name                = var.mysql_private_dns_zone_name
  resource_group_name = var.resource_group_name
}

# Reference PostgreSQL Private DNS Zone (if it exists)
data "azurerm_private_dns_zone" "postgresql" {
  count               = var.postgresql_private_dns_zone_name != "" ? 1 : 0
  name                = var.postgresql_private_dns_zone_name
  resource_group_name = var.resource_group_name
}

# Link MySQL Private DNS Zone to Container Apps VNet
resource "azurerm_private_dns_zone_virtual_network_link" "mysql_container_apps" {
  count                 = var.mysql_private_dns_zone_name != "" ? 1 : 0
  name                  = "${var.app_name}-mysql-dns-link-container-apps-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = data.azurerm_private_dns_zone.mysql[0].name
  virtual_network_id    = azurerm_virtual_network.container_apps.id
  registration_enabled  = false

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Link PostgreSQL Private DNS Zone to Container Apps VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql_container_apps" {
  count                 = var.postgresql_private_dns_zone_name != "" ? 1 : 0
  name                  = "${var.app_name}-postgresql-dns-link-container-apps-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = data.azurerm_private_dns_zone.postgresql[0].name
  virtual_network_id    = azurerm_virtual_network.container_apps.id
  registration_enabled  = false

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Container Apps Environment (shared environment for both apps)
# Note: VNet integration can be added later if needed via infrastructure_subnet_id
# For now, using basic setup to avoid subnet delegation conflicts
resource "azurerm_container_app_environment" "main" {
  name                       = "${var.app_name}-env-${var.environment}"
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  # infrastructure_subnet_id removed to avoid "SubnetIsDelegated" error
  # The subnet delegation to Microsoft.App/environments conflicts with AgentPoolProfile usage
  # If VNet integration is required, configure it separately or use a different subnet

  tags = {
    Environment = var.environment
    Application = var.app_name
  }

  depends_on = [
    null_resource.register_microsoft_app
  ]
}

# Local values for container app URL construction
locals {
  # Construct frontend URL using environment's default domain pattern
  # Azure Container Apps FQDN pattern: <app-name>.<default-domain>
  app_fqdn = "${var.app_name}-${var.environment}.${replace(azurerm_container_app_environment.main.default_domain, "*.", "")}"
}

data "azurerm_key_vault_secret" "mongodb" {
  name         = "mongodb-uri"
  key_vault_id = data.azurerm_key_vault.main.id
}

data "azurerm_key_vault_secret" "jwt" {
  name         = "jwt-secret"
  key_vault_id = data.azurerm_key_vault.main.id
}

# Reference PostgreSQL connection string from Key Vault (if it exists)
# data "azurerm_key_vault_secret" "postgresql_connection_string" {
#   count        = var.postgresql_private_dns_zone_name != "" ? 1 : 0
#   name         = "postgresql-connection-string"
#   key_vault_id = data.azurerm_key_vault.main.id
# }

# Reference MySQL connection string from Key Vault (if it exists)
# data "azurerm_key_vault_secret" "mysql_connection_string" {
#   count        = var.mysql_private_dns_zone_name != "" ? 1 : 0
#   name         = "mysql-connection-string"
#   key_vault_id = data.azurerm_key_vault.main.id
# }

# Create a user-assigned managed identity for the container app (for backend secrets)
resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.app_name}-identity-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

# Grant container app's identity access to Key Vault using RBAC
resource "azurerm_role_assignment" "app_keyvault_secrets_user" {
  scope                = data.azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id

  depends_on = [
    azurerm_user_assigned_identity.app
  ]
}

# Grant container app access to Key Vault
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = data.azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Single Container App with both Frontend and Backend containers
# Similar to docker-compose, both containers run in the same app and can communicate via localhost
resource "azurerm_container_app" "main" {
  name                         = "${var.app_name}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = data.azurerm_resource_group.main.name
  revision_mode                = var.container_app_revision_mode

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
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
    key_vault_secret_id = data.azurerm_key_vault_secret.mongodb.id
    identity            = azurerm_user_assigned_identity.app.id
  }

  secret {
    name                = "jwt-secret"
    key_vault_secret_id = data.azurerm_key_vault_secret.jwt.id
    identity            = azurerm_user_assigned_identity.app.id
  }

  # # PostgreSQL connection string secret (if PostgreSQL is configured)
  # dynamic "secret" {
  #   for_each = var.postgresql_private_dns_zone_name != "" ? [1] : []
  #   content {
  #     name                = "postgresql-connection-string"
  #     key_vault_secret_id = data.azurerm_key_vault_secret.postgresql_connection_string[0].id
  #     identity            = azurerm_user_assigned_identity.app.id
  #   }
  # }

  # # MySQL connection string secret (if MySQL is configured)
  # dynamic "secret" {
  #   for_each = var.mysql_private_dns_zone_name != "" ? [1] : []
  #   content {
  #     name                = "mysql-connection-string"
  #     key_vault_secret_id = data.azurerm_key_vault_secret.mysql_connection_string[0].id
  #     identity            = azurerm_user_assigned_identity.app.id
  #   }
  # }

  template {
    # Combined replicas for both containers
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    # Backend Container
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

      # FRONTEND_URL for CORS - using the app's FQDN since frontend is exposed externally
      env {
        name  = "FRONTEND_URL"
        value = "https://${local.app_fqdn}"
      }

      env {
        name        = "MONGODB_URI"
        secret_name = "mongodb-uri"
      }

      env {
        name        = "JWT_SECRET"
        secret_name = "jwt-secret"
      }

      # PostgreSQL connection string environment variable (if PostgreSQL is configured)
      # dynamic "env" {
      #   for_each = var.postgresql_private_dns_zone_name != "" ? [1] : []
      #   content {
      #     name        = "POSTGRESQL_CONNECTION_STRING"
      #     secret_name = "postgresql-connection-string"
      #   }
      # }

      # MySQL connection string environment variable (if MySQL is configured)
      # dynamic "env" {
      #   for_each = var.mysql_private_dns_zone_name != "" ? [1] : []
      #   content {
      #     name        = "MYSQL_CONNECTION_STRING"
      #     secret_name = "mysql-connection-string"
      #   }
      # }

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

    # Frontend Container
    container {
      name   = "frontend"
      image  = "${data.azurerm_container_registry.main.login_server}/${var.app_name}/frontend:latest"
      cpu    = var.frontend_cpu
      memory = var.frontend_memory

      # BACKEND_URL not set - defaults to empty string for relative URLs
      # Nginx in frontend container proxies /api/* requests to backend container (localhost:5500)
      # Browser makes requests to same origin (frontend ingress), nginx handles routing to backend

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

  # Expose frontend via ingress on port 5173
  # Backend is not exposed externally - nginx in frontend container proxies /api/* to backend (localhost:5500)
  # Browser makes requests to same origin (frontend ingress URL), nginx routes to backend internally
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
    Component   = "fullstack"
  }
}

# Note: Both containers run in the same Container App, similar to docker-compose
# - Backend runs on port 5500 (not exposed externally)
# - Frontend runs on port 5173 and is exposed via ingress
# - Nginx in frontend container proxies /api/* requests to backend (localhost:5500)
# - Browser makes requests to same origin (frontend ingress), nginx handles routing to backend
# - This avoids CORS issues and allows backend to remain internal-only

