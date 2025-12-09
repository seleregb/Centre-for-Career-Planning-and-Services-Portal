# Container Apps Module for CCPS Portal
# This module deploys Container Apps Environment and Container Apps
# Note: ACR must be deployed first and images must be pushed before deploying this

# Log Analytics Workspace for Container Apps (must be created before Container Apps Environment)
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.app_name}-law-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
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
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.2.0.0/16"]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Subnet for Container Apps Environment (dedicated subnet for VNet integration)
resource "azurerm_subnet" "container_apps" {
  name                 = "${var.app_name}-container-apps-subnet-${var.environment}"
  resource_group_name  = var.resource_group_name
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
  location                   = var.location
  resource_group_name        = var.resource_group_name
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
  name         = "mongodb-connection-string"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "jwt" {
  name         = "jwt-secret"
  key_vault_id = var.key_vault_id
}

# Create a user-assigned managed identity for the container app (for backend secrets)
resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.app_name}-identity-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Grant container app's identity access to Key Vault using RBAC
resource "azurerm_role_assignment" "app_keyvault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id

  depends_on = [
    azurerm_user_assigned_identity.app
  ]
}

# Grant container app access to Key Vault
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = var.key_vault_id
  tenant_id    = var.tenant_id
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
  resource_group_name          = var.resource_group_name
  revision_mode                = var.container_app_revision_mode

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  registry {
    server               = var.acr_login_server
    username             = var.acr_admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = var.acr_admin_password
  }

  secret {
    name                = "mongodb-connection-string"
    key_vault_secret_id = data.azurerm_key_vault_secret.mongodb.id
    identity            = azurerm_user_assigned_identity.app.id
  }

  secret {
    name                = "jwt-secret"
    key_vault_secret_id = data.azurerm_key_vault_secret.jwt.id
    identity            = azurerm_user_assigned_identity.app.id
  }

  template {
    # Combined replicas for both containers
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    # Backend Container
    container {
      name   = "backend"
      image  = "${var.acr_login_server}/${var.app_name}/backend:latest"
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
        secret_name = "mongodb-connection-string"
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

    # Frontend Container
    container {
      name   = "frontend"
      image  = "${var.acr_login_server}/${var.app_name}/frontend:latest"
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

