# Production Environment Variables - ACR

environment = "prod"
location    = "canadacentral"

resource_group_name = "rg-ccps-portal-prod"
app_name            = "ccps-portal"

prevent_resource_group_deletion = true

# Azure Container Registry Configuration
acr_sku                   = "Premium"
acr_admin_enabled         = true

