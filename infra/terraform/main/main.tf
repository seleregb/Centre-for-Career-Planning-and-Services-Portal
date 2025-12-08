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
    key_vault {
      recover_soft_deleted_secrets          = true
      purge_soft_deleted_secrets_on_destroy = true
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
    "Restore",
    "Purge"
  ]
}

# Key Vault Secret for MongoDB Atlas Connection String
resource "azurerm_key_vault_secret" "mongodb_connection_string" {
  name         = "mongodb-connection-string"
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
  name         = "jwt-secret"
  value        = var.jwt_secret
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

module "azure_container_registry" {
  source = "../modules/acr"
  
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  app_name            = var.app_name
  acr_sku             = var.acr_sku
  acr_admin_enabled   = var.acr_admin_enabled
  
  depends_on = [azurerm_resource_group.main]
}

module "db" {
  source = "../modules/db"
  
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  app_name            = var.app_name
  key_vault_id        = azurerm_key_vault.main.id
  
  # PostgreSQL Configuration
  postgresql_server_name         = var.postgresql_server_name
  postgresql_admin_username      = var.postgresql_admin_username
  postgresql_admin_password      = var.postgresql_admin_password
  postgresql_version             = var.postgresql_version
  postgresql_database_name       = var.postgresql_database_name
  postgresql_storage_mb          = var.postgresql_storage_mb
  postgresql_sku_name            = var.postgresql_sku_name
  postgresql_backup_retention_days = var.postgresql_backup_retention_days
  
  # MySQL Configuration
  mysql_server_name         = var.mysql_server_name
  mysql_admin_username      = var.mysql_admin_username
  mysql_admin_password      = var.mysql_admin_password
  mysql_version             = var.mysql_version
  mysql_database_name       = var.mysql_database_name
  mysql_storage_mb          = var.mysql_storage_mb
  mysql_storage_size_gb     = var.mysql_storage_size_gb
  mysql_storage_auto_grow_enabled = var.mysql_storage_auto_grow_enabled
  mysql_storage_iops        = var.mysql_storage_iops
  mysql_sku_name           = var.mysql_sku_name
  mysql_backup_retention_days = var.mysql_backup_retention_days
  
  depends_on = [azurerm_resource_group.main, azurerm_key_vault.main]
}

module "container_apps" {
  count  = var.deploy_container_apps ? 1 : 0
  source = "../modules/container-apps"
  
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  app_name            = var.app_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  key_vault_id        = azurerm_key_vault.main.id
  
  # ACR Configuration
  acr_login_server   = module.azure_container_registry.acr_login_server
  acr_admin_username = module.azure_container_registry.acr_admin_username
  acr_admin_password = module.azure_container_registry.acr_admin_password
  
  # Container Apps Configuration
  container_app_revision_mode = var.container_app_revision_mode
  min_replicas                = var.min_replicas
  max_replicas                 = var.max_replicas
  backend_cpu                  = var.backend_cpu
  backend_memory               = var.backend_memory
  frontend_cpu               = var.frontend_cpu
  frontend_memory             = var.frontend_memory
  
  # Database VNet Configuration (optional)
  mysql_vnet_name             = try(module.db.mysql_vnet_name, "")
  postgresql_vnet_name        = try(module.db.postgresql_vnet_name, "")
  mysql_private_dns_zone_name  = try(module.db.mysql_private_dns_zone_name, "")
  postgresql_private_dns_zone_name = try(module.db.postgresql_private_dns_zone_name, "")
  
  depends_on = [
    module.azure_container_registry,
    module.db,
    azurerm_key_vault_secret.mongodb_connection_string,
    azurerm_key_vault_secret.jwt_secret
  ]
}