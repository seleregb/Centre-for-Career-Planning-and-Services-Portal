# Development Environment Variables

environment = "dev"
location    = "eastus"

resource_group_name = "rg-ccps-portal-dev"
app_name            = "ccps-portal"

prevent_resource_group_deletion = false

# Key Vault Configuration
key_vault_soft_delete_retention_days = 7
key_vault_purge_protection_enabled   = false
key_vault_network_acls               = null

# Backend App Service Configuration
backend_sku              = "B1"
backend_always_on        = false
backend_http2_enabled    = false
backend_minimum_tls_version = "1.2"
backend_ftps_state       = "Disabled"

# Frontend Configuration
frontend_sku              = "B1"
frontend_always_on        = false
frontend_http2_enabled    = false
frontend_minimum_tls_version = "1.2"
frontend_ftps_state       = "Disabled"

# Azure Container Registry Configuration
acr_sku                   = "Basic"
acr_admin_enabled         = true

# Secrets - These should be provided via environment variables or Azure Key Vault
# mongodb_atlas_connection_string = "mongodb+srv://user:password@cluster.mongodb.net/dbname?retryWrites=true&w=majority"
# jwt_secret = "your-secret-jwt-key-here"

