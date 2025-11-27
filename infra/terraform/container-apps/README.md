# Container Apps Terraform Configuration

This directory contains Terraform configuration for deploying Azure Container Apps (Environment, Backend, and Frontend apps).

## Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0 installed
- Azure subscription with appropriate permissions
- **ACR must be deployed first** (see `../acr/` directory)
- **Container images must be pushed to ACR** before deploying Container Apps

## Directory Structure

```
container-apps/
├── main.tf          # Container Apps resources
├── variables.tf     # Variable definitions
├── outputs.tf       # Output definitions
├── dev/
│   ├── dev.conf     # Development backend configuration
│   └── dev.tfvars   # Development environment variables
├── stage/
│   ├── stage.conf   # Staging backend configuration
│   └── stage.tfvars # Staging environment variables
└── prod/
    ├── prod.conf    # Production backend configuration
    └── prod.tfvars  # Production environment variables
```

## Dependencies

This configuration references the following resources that must already exist:
- **Resource Group** - Created by ACR deployment
- **Azure Container Registry** - Created by ACR deployment
- **Key Vault** - Created by main infrastructure deployment

The configuration uses Terraform data sources to reference these existing resources.

## Usage

### Initialize Terraform

```bash
cd container-apps

# Development
terraform init -backend-config=dev/dev.conf

# Staging
terraform init -backend-config=stage/stage.conf

# Production
terraform init -backend-config=prod/prod.conf
```

### Plan Changes

```bash
# Development
terraform plan -var-file=dev/dev.tfvars

# Staging
terraform plan -var-file=stage/stage.tfvars

# Production
terraform plan -var-file=prod/prod.tfvars
```

### Apply Changes

```bash
# Development
terraform apply -var-file=dev/dev.tfvars

# Staging
terraform apply -var-file=stage/stage.tfvars

# Production
terraform apply -var-file=prod/prod.tfvars
```

## Deployment Order

1. **Deploy ACR** (see `../acr/` directory)
2. **Build and push container images** to ACR (via CI/CD pipeline)
3. **Deploy Container Apps** (this directory)

**Important**: Container images must exist in ACR with the `:latest` tag before deploying Container Apps, otherwise the deployment will fail.

## Required Secrets

The following secrets must be provided (via environment variables or `.tfvars`):
- `mongodb_atlas_connection_string` - MongoDB Atlas connection string
- `jwt_secret` - JWT secret for authentication

Example:
```bash
export TF_VAR_mongodb_atlas_connection_string="your-connection-string"
export TF_VAR_jwt_secret="your-jwt-secret"
terraform apply -var-file=dev/dev.tfvars
```

## Outputs

After deployment, this configuration outputs:
- `container_app_environment_name` - Name of the Container Apps Environment
- `backend_container_app_name` - Name of the backend Container App
- `backend_container_app_url` - URL of the backend Container App
- `frontend_container_app_name` - Name of the frontend Container App
- `frontend_container_app_url` - URL of the frontend Container App
- `backend_identity_principal_id` - Principal ID of backend managed identity (sensitive)
- `frontend_identity_principal_id` - Principal ID of frontend managed identity (sensitive)

