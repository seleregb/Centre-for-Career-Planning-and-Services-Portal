# Backend configuration for Terraform state management
# This stores state in Azure Storage Account for all environments (dev, stage, prod)

terraform {
  backend "azurerm" {
    # These values should be provided via backend configuration or environment variables
    # resource_group_name  = "rg-terraform-state"
    # storage_account_name = "stterraformstate"
    # container_name       = "tfstate"
    # key                  = "terraform.tfstate"  # This will be overridden per environment
  }
}

# Note: Initialize backend with:
# terraform init -backend-config="resource_group_name=rg-terraform-state" \
#                -backend-config="storage_account_name=stterraformstate" \
#                -backend-config="container_name=tfstate" \
#                -backend-config="key=dev/terraform.tfstate"  # or stage/terraform.tfstate, prod/terraform.tfstate

