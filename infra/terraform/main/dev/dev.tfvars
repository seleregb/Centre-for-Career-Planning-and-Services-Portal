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

# PostgreSQL Serverless Database Configuration
# Uncomment and configure to enable PostgreSQL database
# postgresql_server_name      = "ccps-portal-psql-dev"  # Must be globally unique
# postgresql_admin_username   = "psqladmin"
# postgresql_admin_password   = ""  # Provide via TF_VAR_postgresql_admin_password
# postgresql_version          = "16"
# postgresql_database_name    = "ccpsportal"
# postgresql_storage_mb       = 32768  # Minimum 32768 MB (32 GB)
# postgresql_sku_name         = "B_Standard_B1ms"  # Burstable tier for serverless scaling
# postgresql_backup_retention_days = 7

# MySQL Serverless Database Configuration
# Uncomment and configure to enable MySQL database
# mysql_server_name           = "ccps-portal-mysql-dev"  # Must be globally unique
# mysql_admin_username        = "mysqladmin"
# mysql_admin_password        = ""  # Provide via TF_VAR_mysql_admin_password
# mysql_version               = "8.0.21"
# mysql_database_name         = "ccpsportal"
# mysql_storage_size_gb       = 20  # Minimum 20 GB
# mysql_storage_auto_grow_enabled = true
# mysql_storage_iops          = 360
# mysql_sku_name              = "Standard_B1ms"  # Burstable tier for serverless scaling
# mysql_backup_retention_days = 7

