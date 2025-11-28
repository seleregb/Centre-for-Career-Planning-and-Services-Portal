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

# Virtual Network for Databases
resource "azurerm_virtual_network" "database" {
  name                = "${var.app_name}-db-vnet-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Subnet for PostgreSQL
resource "azurerm_subnet" "postgresql" {
  name                 = "${var.app_name}-postgresql-subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.database.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "delegation-postgresql"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Subnet for MySQL
resource "azurerm_subnet" "mysql" {
  name                 = "${var.app_name}-mysql-subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.database.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "delegation-mysql"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# PostgreSQL Flexible Server (Serverless - Burstable Tier)
# Burstable tier provides cost-effective serverless-like scaling for development and small workloads
resource "azurerm_postgresql_flexible_server" "main" {
  count                         = var.postgresql_server_name != "" ? 1 : 0
  name                          = var.postgresql_server_name
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  version                       = var.postgresql_version
  delegated_subnet_id           = azurerm_subnet.postgresql.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql[0].id
  administrator_login           = var.postgresql_admin_username
  administrator_password        = var.postgresql_admin_password
  zone                          = "1"
  geo_redundant_backup_enabled  = false
  backup_retention_days         = var.postgresql_backup_retention_days
  public_network_access_enabled = false

  storage_mb = var.postgresql_storage_mb

  # Burstable SKU for serverless-like cost-effective scaling
  # B_Standard_B1ms provides 1 vCore, 2GB RAM with burstable performance
  sku_name = var.postgresql_sku_name

  # Serverless configuration - high availability disabled for cost savings
  high_availability {
    mode = "SameZone"
  }

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql" {
  count               = var.postgresql_server_name != "" ? 1 : 0
  name                = "${replace(var.postgresql_server_name, "-", "")}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Private DNS Zone Virtual Network Link for PostgreSQL
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  count                 = var.postgresql_server_name != "" ? 1 : 0
  name                  = "${var.app_name}-postgresql-vnet-link-${var.environment}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql[0].name
  virtual_network_id    = azurerm_virtual_network.database.id
  registration_enabled  = false

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  count     = var.postgresql_server_name != "" ? 1 : 0
  name      = var.postgresql_database_name
  server_id = azurerm_postgresql_flexible_server.main[0].id
  collation = "en_US.utf8"
  charset   = "utf8"

  depends_on = [azurerm_postgresql_flexible_server.main]
}

# MySQL Flexible Server (Serverless - Burstable Tier)
# Burstable tier provides cost-effective serverless-like scaling for development and small workloads
resource "azurerm_mysql_flexible_server" "main" {
  count                        = var.mysql_server_name != "" ? 1 : 0
  name                         = var.mysql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  administrator_login          = var.mysql_admin_username
  administrator_password       = var.mysql_admin_password
  version                      = var.mysql_version
  delegated_subnet_id          = azurerm_subnet.mysql.id
  private_dns_zone_id          = azurerm_private_dns_zone.mysql[0].id
  zone                         = "1"
  backup_retention_days        = var.mysql_backup_retention_days
  geo_redundant_backup_enabled = false

  storage {
    auto_grow_enabled = var.mysql_storage_auto_grow_enabled
    size_gb           = var.mysql_storage_size_gb
    iops              = var.mysql_storage_iops
  }

  # Burstable SKU for serverless-like cost-effective scaling
  # Standard_B1ms provides 1 vCore, 2GB RAM with burstable performance
  sku_name = var.mysql_sku_name

  # Serverless configuration - high availability disabled for cost savings
  high_availability {
    mode = "SameZone"
  }

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]
}

# Private DNS Zone for MySQL
resource "azurerm_private_dns_zone" "mysql" {
  count               = var.mysql_server_name != "" ? 1 : 0
  name                = "${replace(var.mysql_server_name, "-", "")}.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Private DNS Zone Virtual Network Link for MySQL
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  count                 = var.mysql_server_name != "" ? 1 : 0
  name                  = "${var.app_name}-mysql-vnet-link-${var.environment}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql[0].name
  virtual_network_id    = azurerm_virtual_network.database.id
  registration_enabled  = false

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# MySQL Database
resource "azurerm_mysql_flexible_database" "main" {
  resource_group_name = azurerm_resource_group.main.name
  count               = var.mysql_server_name != "" ? 1 : 0
  name                = var.mysql_database_name
  server_name         = azurerm_mysql_flexible_server.main[0].name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"

  depends_on = [azurerm_mysql_flexible_server.main]
}

# Key Vault Secret for PostgreSQL Connection String
resource "azurerm_key_vault_secret" "postgresql_connection_string" {
  count        = var.postgresql_server_name != "" ? 1 : 0
  name         = "postgresql-connection-string"
  value        = "postgresql://${var.postgresql_admin_username}:${var.postgresql_admin_password}@${azurerm_postgresql_flexible_server.main[0].fqdn}:5432/${var.postgresql_database_name}?sslmode=require"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault_access_policy.current_user,
    azurerm_postgresql_flexible_server_database.main
  ]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Key Vault Secret for MySQL Connection String
resource "azurerm_key_vault_secret" "mysql_connection_string" {
  count        = var.mysql_server_name != "" ? 1 : 0
  name         = "mysql-connection-string"
  value        = "mysql://${var.mysql_admin_username}:${var.mysql_admin_password}@${azurerm_mysql_flexible_server.main[0].fqdn}:3306/${var.mysql_database_name}?ssl-mode=REQUIRED"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault_access_policy.current_user,
    azurerm_mysql_flexible_database.main
  ]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}