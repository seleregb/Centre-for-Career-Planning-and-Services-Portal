# Variables for ACR Terraform configuration

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

