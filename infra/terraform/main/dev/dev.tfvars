# Development Environment Variables

environment = "dev"
location    = "canadacentral"

resource_group_name = "rg-ccps-portal-dev"
app_name            = "ccps-portal"

prevent_resource_group_deletion = false

# Key Vault Configuration
key_vault_soft_delete_retention_days = 7
key_vault_purge_protection_enabled   = false
key_vault_network_acls               = null

# Azure Container Registry Configuration
acr_sku                   = "Basic"
acr_admin_enabled         = true

# Secrets should be provided via environment variables or Azure Key Vault
# mongodb_atlas_connection_string = ""
# jwt_secret = ""

# PostgreSQL Serverless Database Configuration (eastus2)
postgresql_server_name      = "ccpsportal-dev-psql"  # Must be globally unique
postgresql_admin_username   = "psqladmin"
postgresql_admin_password   = "P@tience1$key"  # Provide via TF_VAR_postgresql_admin_password
postgresql_version          = "16"
postgresql_database_name    = "ccpsportal-dev"
postgresql_storage_mb       = 32768  # Minimum 32768 MB (32 GB)
postgresql_sku_name         = "B_Standard_B1ms"  # Burstable tier for serverless scaling
postgresql_backup_retention_days = 7
postgresql_location         = "eastus2"

# MySQL Serverless Database Configuration (eastus)
mysql_server_name           = "ccpsportal-dev-mysql"  # Must be globally unique
mysql_admin_username        = "mysqladmin"
mysql_admin_password        = "P@tience1$key"  # Provide via TF_VAR_mysql_admin_password
mysql_version               = "8.0.21"
mysql_database_name         = "ccpsportal-dev"
mysql_storage_size_gb       = 20  # Minimum 20 GB
mysql_storage_auto_grow_enabled = true
mysql_storage_iops          = 360
mysql_sku_name              = "B_Standard_B1ms"  # Burstable tier for serverless scaling
mysql_backup_retention_days = 7
mysql_location              = "westus2"

# Container Apps Configuration
container_app_revision_mode = "Single"

# Single Container App Configuration (contains both frontend and backend)
# Both containers scale together
min_replicas = 1
max_replicas = 10

# Backend Container Configuration
backend_cpu    = 0.5
backend_memory = "1.0Gi"

# Frontend Container Configuration
frontend_cpu    = 0.25
frontend_memory = "0.5Gi"

# Secrets should be provided via environment variables or Azure Key Vault
# mongodb_atlas_connection_string = ""
# jwt_secret = ""

# Database VNet Configuration (for connecting to databases in private VNets)
# These values should match the VNet names created by the database Terraform module
mysql_vnet_name                = "ccps-portal-mysql-vnet-dev"
postgresql_vnet_name           = "ccps-portal-postgresql-vnet-dev"

# Database Private DNS Zone Configuration (for DNS resolution)
# These values should match the private DNS zone names created by the database Terraform module
# Format: <server-name-without-dashes>.mysql.database.azure.com or .postgres.database.azure.com
mysql_private_dns_zone_name    = "ccpsportaldevmysql.mysql.database.azure.com"
postgresql_private_dns_zone_name = "ccpsportaldevpsql.postgres.database.azure.com"