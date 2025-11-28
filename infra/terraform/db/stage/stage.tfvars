# Staging Environment Variables - Database

environment = "stage"
resource_group_name = "rg-ccps-portal-stage"
app_name            = "ccps-portal"

# PostgreSQL Serverless Database Configuration (eastus2)
# Uncomment and configure to enable PostgreSQL database
# postgresql_server_name      = "ccps-portal-psql-stage"  # Must be globally unique
# postgresql_admin_username   = "psqladmin"
# postgresql_admin_password   = ""  # Provide via TF_VAR_postgresql_admin_password
# postgresql_version          = "16"
# postgresql_database_name    = "ccpsportal"
# postgresql_storage_mb       = 32768  # Minimum 32768 MB (32 GB)
# postgresql_sku_name         = "B_Standard_B1ms"  # Burstable tier for serverless scaling
# postgresql_backup_retention_days = 7
postgresql_location         = "eastus2"

# MySQL Serverless Database Configuration (eastus)
# Uncomment and configure to enable MySQL database
# mysql_server_name           = "ccps-portal-mysql-stage"  # Must be globally unique
# mysql_admin_username        = "mysqladmin"
# mysql_admin_password        = ""  # Provide via TF_VAR_mysql_admin_password
# mysql_version               = "8.0.21"
# mysql_database_name         = "ccpsportal"
# mysql_storage_size_gb       = 20  # Minimum 20 GB
# mysql_storage_auto_grow_enabled = true
# mysql_storage_iops          = 360
# mysql_sku_name              = "Standard_B1ms"  # Burstable tier for serverless scaling
# mysql_backup_retention_days = 7
mysql_location              = "eastus"

