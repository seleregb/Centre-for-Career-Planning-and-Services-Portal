# Terraform Infrastructure Configuration

This directory contains Terraform configurations for deploying the CCPS Portal application to Azure across three environments: **dev**, **stage**, and **prod**.

## Directory Structure

```
infra/terraform/
├── backend/              # Terraform state management configuration
│   ├── backend.tf       # Backend configuration for Azure Storage
│   └── README.md        # Backend setup instructions
│
└── main/                # Main infrastructure configurations
    ├── main.tf          # Single main Terraform configuration file
    ├── variables.tf     # Variable definitions
    ├── outputs.tf       # Output definitions
    ├── dev.tfvars       # Development environment variables
    ├── dev.conf         # Development backend configuration
    ├── stage.tfvars     # Staging environment variables
    ├── stage.conf       # Staging backend configuration
    ├── prod.tfvars      # Production environment variables
    ├── prod.conf        # Production backend configuration
    └── README.md        # Usage instructions
```

## Architecture Overview

The infrastructure provisions the following Azure resources for each environment:

### Resources Created

1. **Resource Group** - Container for all resources
2. **Azure Key Vault** - Secure storage for secrets (MongoDB connection string, JWT secrets)
3. **App Service Plan (Backend)** - Hosting plan for Node.js Express backend
4. **Linux Web App (Backend)** - Node.js Express application
5. **App Service Plan (Frontend)** - Hosting plan for React frontend
6. **Static Web App (Frontend)** - React application hosting

### Key Features

- **State Management**: All Terraform state files are stored in a centralized Azure Storage Account
- **Secrets Management**: MongoDB Atlas connection strings and JWT secrets are stored in Azure Key Vault
- **Managed Identity**: Backend App Service uses managed identity to access Key Vault
- **Environment-Specific Configuration**: Each environment has its own configuration with appropriate SKUs and settings

## Prerequisites

1. **Azure CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **Azure Subscription** with appropriate permissions
4. **MongoDB Atlas** cluster and connection string

## Initial Setup

### 1. Create Terraform State Storage

First, create the Azure Storage Account and Container for Terraform state:

```bash
# Set variables
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstate$(date +%s | tail -c 5)"  # Append random suffix
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# Create storage container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT
```

### 2. Configure Backend

Update the `.conf` files in the `main/` directory with your storage account details:

**Example: `main/dev.conf`**
```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "stterraformstate12345"
container_name       = "tfstate"
key                  = "dev/terraform.tfstate"
```

Update `dev.conf`, `stage.conf`, and `prod.conf` with your actual storage account name.

### 3. Configure Variables

The `.tfvars` files are already created with default values. Update them with your specific values:

- `main/dev.tfvars` - Development environment variables
- `main/stage.tfvars` - Staging environment variables  
- `main/prod.tfvars` - Production environment variables

**Important**: Never commit `.tfvars` files with actual secrets to version control. Use environment variables or Terraform Cloud/Enterprise for sensitive values.

## Usage

### Initialize Terraform

For each environment, initialize Terraform with the appropriate backend configuration:

```bash
cd main

# Development
terraform init -backend-config=dev.conf

# Staging
terraform init -backend-config=stage.conf

# Production
terraform init -backend-config=prod.conf
```

### Plan Changes

```bash
cd main

# Development
terraform plan -var-file=dev.tfvars

# Staging
terraform plan -var-file=stage.tfvars

# Production
terraform plan -var-file=prod.tfvars
```

### Apply Changes

```bash
cd main

# Development
terraform apply -var-file=dev.tfvars

# Staging
terraform apply -var-file=stage.tfvars

# Production
terraform apply -var-file=prod.tfvars
```

### Destroy Infrastructure

```bash
terraform destroy
```

## Environment-Specific Configurations

### Development
- **Backend SKU**: B1 (Basic)
- **Frontend SKU**: Free
- **Key Vault**: Standard tier
- **Always On**: Disabled

### Staging
- **Backend SKU**: S1 (Standard)
- **Frontend SKU**: Standard
- **Key Vault**: Standard tier
- **Always On**: Enabled

### Production
- **Backend SKU**: P1v3 (Premium)
- **Frontend SKU**: Standard
- **Key Vault**: Standard tier with purge protection
- **Always On**: Enabled
- **Security**: Enhanced with network ACLs and TLS 1.2 minimum

## Secrets Management

### Setting Secrets in Key Vault

Secrets can be set via Terraform (as shown in the configuration) or manually via Azure CLI:

```bash
# Set MongoDB connection string
az keyvault secret set \
  --vault-name <key-vault-name> \
  --name "MongoDBAtlasConnectionString" \
  --value "<your-connection-string>"

# Set JWT secret
az keyvault secret set \
  --vault-name <key-vault-name> \
  --name "JWTSecret" \
  --value "<your-jwt-secret>"
```

### Accessing Secrets in App Service

The backend App Service is configured to reference secrets from Key Vault using the `@Microsoft.KeyVault()` syntax. The App Service uses managed identity to authenticate to Key Vault.

## Backend Application Configuration

The backend App Service expects the following environment variables:

- `MONGODB_URI` - MongoDB Atlas connection string (from Key Vault)
- `JWT_SECRET` - JWT signing secret (from Key Vault)
- `NODE_ENV` - Environment name (dev/stage/prod)
- `PORT` - Port number (default: 8080)

## Frontend Application Configuration

The React frontend is deployed as a Static Web App. You'll need to configure the API endpoint in your frontend code to point to the backend App Service URL.

## Troubleshooting

### Common Issues

1. **Backend initialization fails**: Ensure you have the correct Azure credentials configured (`az login`)
2. **Key Vault access denied**: Verify the App Service managed identity has been granted access to Key Vault
3. **State lock errors**: Check if another Terraform operation is in progress or manually unlock the state

### Useful Commands

```bash
# View current state
terraform show

# List resources
terraform state list

# Import existing resources
terraform import <resource_type>.<resource_name> <resource_id>

# Unlock state (if locked)
terraform force-unlock <lock-id>
```

## Best Practices

1. **Never commit sensitive data**: Use `.gitignore` to exclude `.tfvars` files with secrets. The `.conf` files are safe to commit as they only contain backend configuration.
2. **Single main.tf**: One main configuration file is used for all environments, configured via `.tfvars` files
3. **Review plans before applying**: Always run `terraform plan` before `terraform apply`
4. **Version control**: Commit Terraform configuration files (`main.tf`, `variables.tf`, `outputs.tf`, `.conf` files) to version control
5. **Backup state**: Regularly backup your Terraform state files
6. **Use variables**: All environment-specific values are configured via `.tfvars` files

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)
- [Azure Static Web Apps Documentation](https://docs.microsoft.com/azure/static-web-apps/)

