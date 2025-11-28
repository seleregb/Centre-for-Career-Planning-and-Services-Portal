# Staging Environment Variables - Container Apps

environment = "stage"

resource_group_name = "rg-ccps-portal-stage"
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

