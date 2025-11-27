# ACR Terraform configuration for CCPS Portal
# This file deploys the Azure Container Registry and its dependencies

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Backend configuration is provided via -backend-config during init
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = var.prevent_resource_group_deletion
    }
  }
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Resource Group
data "azurerm_resource_group" "acr" {
  name = var.resource_group_name
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.app_name, "-", "")}acr${var.environment}"
  resource_group_name = data.azurerm_resource_group.acr.name
  location            = data.azurerm_resource_group.acr.location
  sku                 = var.acr_sku           # Basic, Standard, Premium
  admin_enabled       = var.acr_admin_enabled # true or false

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

