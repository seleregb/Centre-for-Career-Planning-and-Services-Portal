# Terraform Backend Configuration

This directory contains the backend configuration for Terraform state management.

## Overview

The Terraform state is stored in an Azure Storage Account within a single resource group that manages state for all three environments: `dev`, `stage`, and `prod`.

## Backend Structure

The state files are organized as follows in the Azure Storage Container:
- `dev/terraform.tfstate`
- `stage/terraform.tfstate`
- `prod/terraform.tfstate`

## Initial Setup

Before using Terraform, you need to create the Azure Storage Account and Container for state management:

```bash
# Create resource group for Terraform state
az group create --name rg-terraform-state --location canadacentral

# Create storage account
az storage account create \
  --name stmcdaterraformstate \
  --resource-group rg-terraform-state \
  --location canadacentral \
  --sku Standard_LRS

# Create storage container
az storage container create \
  --name tfstate \
  --account-name stmcdaterraformstate
```

## Initializing Backend

When initializing Terraform for each environment, specify the appropriate state key:

### Development Environment
```bash
cd ../main/dev
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=stterraformstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev/terraform.tfstate"
```

### Staging Environment
```bash
cd ../main/stage
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=stterraformstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=stage/terraform.tfstate"
```

### Production Environment
```bash
cd ../main/prod
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=stterraformstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod/terraform.tfstate"
```

## Alternative: Using backend.hcl files

You can also create `backend.hcl` files in each environment directory to avoid passing parameters each time:

**main/dev/backend.hcl:**
```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "stterraformstate"
container_name       = "tfstate"
key                  = "dev/terraform.tfstate"
```

Then initialize with:
```bash
terraform init -backend-config=backend.hcl
```

