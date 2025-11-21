# Production Environment Variables

environment = "prod"
location    = "canadacentral"

resource_group_name = "rg-ccps-portal-prod"
app_name            = "ccps-portal"

prevent_resource_group_deletion = true

# Key Vault Configuration
# Set to 0 for immediate deletion when resource group is deleted
# Note: Disabling purge protection reduces security but allows immediate deletion
key_vault_soft_delete_retention_days = 7
key_vault_purge_protection_enabled   = false
key_vault_network_acls = {
  default_action = "Deny"
  bypass         = "AzureServices"
  ip_rules       = [] # Add your IP addresses here for production access
}

# Backend App Service Configuration
backend_sku              = "P1v3"
backend_always_on        = true
backend_http2_enabled    = true
backend_minimum_tls_version = "1.2"
backend_ftps_state       = "Disabled"

# Frontend Configuration
frontend_sku              = "P1v3"
frontend_always_on        = true
frontend_http2_enabled    = true
frontend_minimum_tls_version = "1.2"
frontend_ftps_state       = "Disabled"

# Azure Container Registry Configuration
acr_sku                   = "Premium"
acr_admin_enabled         = true

# Secrets - These should be provided via environment variables or Azure Key Vault
# mongodb_atlas_connection_string = "mongodb+srv://user:password@cluster.mongodb.net/dbname?retryWrites=true&w=majority"
# jwt_secret = "your-secret-jwt-key-here"

