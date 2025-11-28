# Development Environment Variables - Container Apps

environment = "dev"

resource_group_name = "rg-ccps-portal-dev"
app_name            = "ccps-portal"

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

