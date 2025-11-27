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
    "Restore"
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