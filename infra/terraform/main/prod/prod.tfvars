# Production Environment Variables

environment = "prod"
location    = "canadacentral"

resource_group_name = "rg-ccps-portal-prod"
app_name            = "ccps-portal"

prevent_resource_group_deletion = true

# Key Vault Configuration
key_vault_soft_delete_retention_days = 7
key_vault_purge_protection_enabled   = false
key_vault_network_acls = {
  default_action = "Deny"
  bypass         = "AzureServices"
  ip_rules       = [] # Add your IP addresses here for production access
}

# Azure Container Registry Configuration
acr_sku                   = "Premium"
acr_admin_enabled         = true

# Secrets should be provided via environment variables or Azure Key Vault
# mongodb_atlas_connection_string = ""
# jwt_secret = ""

