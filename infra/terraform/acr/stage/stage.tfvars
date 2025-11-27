# Staging Environment Variables - ACR

environment = "stage"
location    = "canadacentral"

resource_group_name = "rg-ccps-portal-stage"
app_name            = "ccps-portal"

prevent_resource_group_deletion = true

# Azure Container Registry Configuration
acr_sku                   = "Standard"
acr_admin_enabled         = true

