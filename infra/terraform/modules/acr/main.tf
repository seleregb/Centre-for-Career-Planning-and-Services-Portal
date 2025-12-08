# ACR Module for CCPS Portal
# This module deploys the Azure Container Registry

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.app_name, "-", "")}acr${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku           # Basic, Standard, Premium
  admin_enabled       = var.acr_admin_enabled # true or false

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

