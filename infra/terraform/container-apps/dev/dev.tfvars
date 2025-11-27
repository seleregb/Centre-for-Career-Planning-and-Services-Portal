# Development Environment Variables - Container Apps

environment = "dev"

resource_group_name = "rg-ccps-portal-dev"
app_name            = "ccps-portal"

# Container Apps Configuration
container_app_revision_mode = "Single"

# Backend Container App Configuration
backend_min_replicas = 1
backend_max_replicas = 10
backend_cpu          = 0.5
backend_memory       = "1.0Gi"

# Frontend Container App Configuration
frontend_min_replicas = 1
frontend_max_replicas = 10
frontend_cpu          = 0.25
frontend_memory       = "0.5Gi"

# Secrets should be provided via environment variables or Azure Key Vault
# mongodb_atlas_connection_string = ""
# jwt_secret = ""

