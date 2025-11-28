# Database Terraform configuration for CCPS Portal
# This file deploys MySQL and PostgreSQL Flexible Servers
# MySQL is deployed in eastus, PostgreSQL is deployed in eastus2

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

# Reference existing Key Vault
data "azurerm_key_vault" "main" {
  name                = "${var.app_name}-kv-${var.environment}"
  resource_group_name = var.resource_group_name
}

# Get service principal for Key Vault access
data "azuread_service_principal" "current_sp" {
  display_name = "tfAzureDevOps"
}

# Ensure Microsoft.DBforMySQL and Microsoft.DBforPostgreSQL providers are registered
resource "null_resource" "register_microsoft_app" {
  provisioner "local-exec" {
    command = "az provider register --namespace Microsoft.DBforMySQL"
  }
  provisioner "local-exec" {
    command = "az provider register --namespace Microsoft.DBforPostgreSQL"
  }
}

# Virtual Network for MySQL Database (eastus)
resource "azurerm_virtual_network" "mysql" {
  count               = var.mysql_server_name != "" ? 1 : 0
  name                = "${var.app_name}-mysql-vnet-${var.environment}"
  location            = var.mysql_location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Subnet for MySQL
resource "azurerm_subnet" "mysql" {
  count                = var.mysql_server_name != "" ? 1 : 0
  name                 = "${var.app_name}-mysql-subnet-${var.environment}"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.mysql[0].name
  address_prefixes     = ["10.0.1.0/24"]
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

# Virtual Network for PostgreSQL Database (eastus2)
resource "azurerm_virtual_network" "postgresql" {
  count               = var.postgresql_server_name != "" ? 1 : 0
  name                = "${var.app_name}-postgresql-vnet-${var.environment}"
  location            = var.postgresql_location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = ["10.1.0.0/16"]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Subnet for PostgreSQL
resource "azurerm_subnet" "postgresql" {
  count                = var.postgresql_server_name != "" ? 1 : 0
  name                 = "${var.app_name}-postgresql-subnet-${var.environment}"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.postgresql[0].name
  address_prefixes     = ["10.1.1.0/24"]
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

# MySQL Flexible Server (in eastus)
resource "azurerm_mysql_flexible_server" "main" {
  count                        = var.mysql_server_name != "" ? 1 : 0
  name                         = var.mysql_server_name
  resource_group_name          = data.azurerm_resource_group.main.name
  location                     = var.mysql_location
  administrator_login          = var.mysql_admin_username
  administrator_password       = var.mysql_admin_password
  version                      = var.mysql_version
  delegated_subnet_id          = azurerm_subnet.mysql[0].id
  private_dns_zone_id          = azurerm_private_dns_zone.mysql[0].id
  backup_retention_days        = var.mysql_backup_retention_days
  geo_redundant_backup_enabled = false

  storage {
    auto_grow_enabled = var.mysql_storage_auto_grow_enabled
    size_gb           = var.mysql_storage_size_gb
    iops              = var.mysql_storage_iops
  }

  # Burstable SKU for serverless-like cost-effective scaling
  # Standard_B1ms provides 1 vCore, 2GB RAM with burstable performance
  # Note: High availability is not supported for burstable SKUs
  sku_name = var.mysql_sku_name

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
  }

  depends_on = [
    azurerm_subnet.mysql,
    azurerm_private_dns_zone_virtual_network_link.mysql,
    null_resource.register_microsoft_app
  ]
}

# Private DNS Zone for MySQL
resource "azurerm_private_dns_zone" "mysql" {
  count               = var.mysql_server_name != "" ? 1 : 0
  name                = "${replace(var.mysql_server_name, "-", "")}.mysql.database.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Private DNS Zone Virtual Network Link for MySQL
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  count                 = var.mysql_server_name != "" ? 1 : 0
  name                  = "${var.app_name}-mysql-vnet-link-${var.environment}"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql[0].name
  virtual_network_id    = azurerm_virtual_network.mysql[0].id
  registration_enabled  = false

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# MySQL Database
resource "azurerm_mysql_flexible_database" "main" {
  count              = var.mysql_server_name != "" ? 1 : 0
  name               = var.mysql_database_name
  server_name        = azurerm_mysql_flexible_server.main[0].name
  resource_group_name = data.azurerm_resource_group.main.name
  charset            = "utf8mb4"
  collation          = "utf8mb4_unicode_ci"

  depends_on = [azurerm_mysql_flexible_server.main]
}

# PostgreSQL Flexible Server (in eastus2)
resource "azurerm_postgresql_flexible_server" "main" {
  count                         = var.postgresql_server_name != "" ? 1 : 0
  name                          = var.postgresql_server_name
  resource_group_name           = data.azurerm_resource_group.main.name
  location                      = var.postgresql_location
  version                       = var.postgresql_version
  delegated_subnet_id           = azurerm_subnet.postgresql[0].id
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
  # Note: High availability is not supported for burstable SKUs
  sku_name = var.postgresql_sku_name

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
  }

  depends_on = [
    azurerm_subnet.postgresql,
    azurerm_private_dns_zone_virtual_network_link.postgresql,
    null_resource.register_microsoft_app
  ]
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql" {
  count               = var.postgresql_server_name != "" ? 1 : 0
  name                = "${replace(var.postgresql_server_name, "-", "")}.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# Private DNS Zone Virtual Network Link for PostgreSQL
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  count                 = var.postgresql_server_name != "" ? 1 : 0
  name                  = "${var.app_name}-postgresql-vnet-link-${var.environment}"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql[0].name
  virtual_network_id    = azurerm_virtual_network.postgresql[0].id
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


# Key Vault Secret for PostgreSQL Connection String
resource "azurerm_key_vault_secret" "postgresql_connection_string" {
  count        = var.postgresql_server_name != "" ? 1 : 0
  name         = "postgresql-connection-string"
  value        = "postgresql://${var.postgresql_admin_username}:${var.postgresql_admin_password}@${azurerm_postgresql_flexible_server.main[0].fqdn}:5432/${var.postgresql_database_name}?sslmode=require"
  key_vault_id = data.azurerm_key_vault.main.id

  depends_on = [
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
  key_vault_id = data.azurerm_key_vault.main.id

  depends_on = [
    azurerm_mysql_flexible_database.main
  ]

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

