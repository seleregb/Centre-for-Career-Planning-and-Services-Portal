# Staging Environment Variables

environment = "stage"
location    = "eastus"

resource_group_name = "rg-ccps-portal-stage"
app_name            = "ccps-portal"

prevent_resource_group_deletion = true

# Key Vault Configuration
key_vault_soft_delete_retention_days = 30
key_vault_purge_protection_enabled   = false
key_vault_network_acls               = null

# Backend App Service Configuration
backend_sku              = "S1"
backend_always_on        = true
backend_http2_enabled    = true
backend_minimum_tls_version = "1.2"
backend_ftps_state       = "Disabled"

# Frontend Configuration
frontend_sku              = "S1"
frontend_always_on        = true
frontend_http2_enabled    = true
frontend_minimum_tls_version = "1.2"
frontend_ftps_state       = "Disabled"

# Azure Container Registry Configuration
acr_sku                   = "Standard"
acr_admin_enabled         = true

# Secrets - These should be provided via environment variables or Azure Key Vault
# mongodb_atlas_connection_string = "mongodb+srv://user:password@cluster.mongodb.net/dbname?retryWrites=true&w=majority"
# jwt_secret = "your-secret-jwt-key-here"

