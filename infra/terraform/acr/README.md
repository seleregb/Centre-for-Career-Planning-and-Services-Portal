# ACR Terraform Configuration

This directory contains Terraform configuration for deploying the Azure Container Registry (ACR) and its dependencies (Resource Group and Storage Account).

## Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0 installed
- Azure subscription with appropriate permissions

## Directory Structure

```
acr/
├── main.tf          # ACR, Resource Group, and Storage Account resources
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

## Usage

### Initialize Terraform

```bash
cd acr

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

1. **Deploy ACR first** (this directory)
2. **Build and push container images** to ACR (via CI/CD pipeline)
3. **Deploy Container Apps** (see `../container-apps/` directory)

## Outputs

After deployment, this configuration outputs:
- `resource_group_name` - Name of the resource group
- `acr_name` - Name of the Azure Container Registry
- `acr_login_server` - Login server URL for the ACR
- `acr_admin_username` - Admin username (sensitive)
- `acr_admin_password` - Admin password (sensitive)

These outputs can be used by the Container Apps deployment or CI/CD pipelines.

