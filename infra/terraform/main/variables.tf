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
  description = "Number of days to retain soft-deleted Key Vault. Set to 0 for immediate deletion when resource group is deleted."
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

# Container Apps Configuration
variable "container_app_revision_mode" {
  description = "Revision mode for Container Apps (Single or Multiple)"
  type        = string
  default     = "Single"
}

# Backend Container App Configuration
variable "backend_min_replicas" {
  description = "Minimum number of replicas for backend Container App"
  type        = number
  default     = 1
}

variable "backend_max_replicas" {
  description = "Maximum number of replicas for backend Container App"
  type        = number
  default     = 10
}

variable "backend_cpu" {
  description = "CPU allocation for backend container (e.g., 0.25, 0.5, 1.0, 2.0)"
  type        = number
  default     = 0.5
}

variable "backend_memory" {
  description = "Memory allocation for backend container (e.g., 0.5Gi, 1.0Gi, 2.0Gi)"
  type        = string
  default     = "1.0Gi"
}

# Frontend Container App Configuration
variable "frontend_min_replicas" {
  description = "Minimum number of replicas for frontend Container App"
  type        = number
  default     = 1
}

variable "frontend_max_replicas" {
  description = "Maximum number of replicas for frontend Container App"
  type        = number
  default     = 10
}

variable "frontend_cpu" {
  description = "CPU allocation for frontend container (e.g., 0.25, 0.5, 1.0, 2.0)"
  type        = number
  default     = 0.25
}

variable "frontend_memory" {
  description = "Memory allocation for frontend container (e.g., 0.5Gi, 1.0Gi, 2.0Gi)"
  type        = string
  default     = "0.5Gi"
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

variable "storage_account_tier" {
  description = "Tier for the general-purpose storage account"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
}

variable "storage_account_kind" {
  description = "Kind of storage account to create"
  type        = string
  default     = "StorageV2"
}

variable "storage_shared_access_key_enabled" {
  description = "Enable shared access keys for the storage account"
  type        = bool
  default     = true
}

# Secrets (should be provided via .tfvars or environment variables)
variable "mongodb_atlas_connection_string" {
  description = "MongoDB Atlas connection string"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jwt_secret" {
  description = "JWT secret for authentication"
  type        = string
  sensitive   = true
  default     = ""
}

variable "subscription_required_role_assignments" {
  description = "Role assignments required for the subscription"
  type        = list(string)
  default     = ["Contributor", "Key Vault Secrets Officer", "Key Vault Administrator"]
}

variable "acr_required_role_assignments" {
  description = "Role assignments required for the ACR"
  type        = list(string)
  default     = ["AcrPush", "Container Registry Repository Contributor"]
}

variable "storage_required_role_assignments" {
  description = "Role assignments required for the storage account"
  type        = list(string)
  default     = ["Storage Blob Data Contributor", "Storage Blob Data Reader"]
}

variable "resource_group_required_role_assignments" {
  description = "Role assignments required for the resource group"
  type        = list(string)
  default     = ["Contributor"]
}

