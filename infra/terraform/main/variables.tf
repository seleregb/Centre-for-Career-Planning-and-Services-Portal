# Variables for Terraform configuration

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "app_name" {
  description = "Application name prefix"
  type        = string
  default     = "ccps-portal"
}

variable "prevent_resource_group_deletion" {
  description = "Prevent deletion of resource group if it contains resources"
  type        = bool
  default     = false
}

# Key Vault Configuration
variable "key_vault_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted Key Vault"
  type        = number
  default     = 7
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = false
}

variable "key_vault_network_acls" {
  description = "Network ACLs for Key Vault. Set to null to disable."
  type = object({
    default_action = string
    bypass         = string
    ip_rules       = list(string)
  })
  default = null
}

# Backend App Service Configuration
variable "backend_sku" {
  description = "SKU for backend App Service Plan"
  type        = string
}

variable "backend_always_on" {
  description = "Enable Always On for backend App Service"
  type        = bool
  default     = false
}

variable "backend_http2_enabled" {
  description = "Enable HTTP/2 for backend App Service"
  type        = bool
  default     = false
}

variable "backend_minimum_tls_version" {
  description = "Minimum TLS version for backend App Service"
  type        = string
  default     = "1.2"
}

variable "backend_ftps_state" {
  description = "FTPS state for backend App Service"
  type        = string
  default     = "Disabled"
}

# Frontend Configuration
variable "frontend_sku" {
  description = "SKU for frontend App Service Plan"
  type        = string
  default     = "B1"
}

variable "frontend_always_on" {
  description = "Enable Always On for frontend App Service"
  type        = bool
  default     = false
}

variable "frontend_http2_enabled" {
  description = "Enable HTTP/2 for frontend App Service"
  type        = bool
  default     = false
}

variable "frontend_minimum_tls_version" {
  description = "Minimum TLS version for frontend App Service"
  type        = string
  default     = "1.2"
}

variable "frontend_ftps_state" {
  description = "FTPS state for frontend App Service"
  type        = string
  default     = "Disabled"
}

# Azure Container Registry Configuration
variable "acr_sku" {
  description = "SKU for Azure Container Registry (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}

variable "acr_admin_enabled" {
  description = "Enable admin user for Azure Container Registry"
  type        = bool
  default     = true
}

# Secrets (should be provided via .tfvars or environment variables)
variable "mongodb_atlas_connection_string" {
  description = "MongoDB Atlas connection string"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret for authentication"
  type        = string
  sensitive   = true
}

