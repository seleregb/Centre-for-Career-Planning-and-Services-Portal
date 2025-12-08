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

# ACR Configuration
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

# Database Configuration
variable "postgresql_server_name" {
  description = "Name of the PostgreSQL Flexible Server (must be globally unique)"
  type        = string
  default     = ""
}

variable "postgresql_admin_username" {
  description = "Administrator username for PostgreSQL server"
  type        = string
  sensitive   = true
  default     = "psqladmin"
}

variable "postgresql_admin_password" {
  description = "Administrator password for PostgreSQL server"
  type        = string
  sensitive   = true
  default     = ""
}

variable "postgresql_version" {
  description = "PostgreSQL server version"
  type        = string
  default     = "16"
}

variable "postgresql_database_name" {
  description = "Name of the PostgreSQL database to create"
  type        = string
  default     = "ccpsportal"
}

variable "postgresql_storage_mb" {
  description = "Storage size for PostgreSQL server in MB (minimum 32768 for serverless)"
  type        = number
  default     = 32768
}

variable "postgresql_sku_name" {
  description = "SKU name for PostgreSQL serverless (Burstable tier for cost-effective scaling). Example: B_Standard_B1ms (1 vCore, 2GB RAM)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgresql_backup_retention_days" {
  description = "Backup retention days for PostgreSQL server"
  type        = number
  default     = 7
}

variable "mysql_server_name" {
  description = "Name of the MySQL Flexible Server (must be globally unique)"
  type        = string
  default     = ""
}

variable "mysql_admin_username" {
  description = "Administrator username for MySQL server"
  type        = string
  sensitive   = true
  default     = "mysqladmin"
}

variable "mysql_admin_password" {
  description = "Administrator password for MySQL server"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mysql_version" {
  description = "MySQL server version"
  type        = string
  default     = "8.0.21"
}

variable "mysql_database_name" {
  description = "Name of the MySQL database to create"
  type        = string
  default     = "ccpsportal"
}

variable "mysql_storage_mb" {
  description = "Storage size for MySQL server in MB (minimum 20480). Deprecated - use mysql_storage_size_gb instead"
  type        = number
  default     = 20480
}

variable "mysql_storage_size_gb" {
  description = "Storage size for MySQL server in GB (minimum 20)"
  type        = number
  default     = 20
}

variable "mysql_storage_auto_grow_enabled" {
  description = "Enable auto-grow for MySQL storage"
  type        = bool
  default     = true
}

variable "mysql_storage_iops" {
  description = "IOPS for MySQL storage"
  type        = number
  default     = 360
}

variable "mysql_sku_name" {
  description = "SKU name for MySQL serverless (Burstable tier for cost-effective scaling). Example: Standard_B1ms (1 vCore, 2GB RAM)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_backup_retention_days" {
  description = "Backup retention days for MySQL server"
  type        = number
  default     = 7
}

# Container Apps Configuration
variable "deploy_container_apps" {
  description = "Set to true to deploy container apps"
  type        = bool
  default     = false
}

variable "container_app_revision_mode" {
  description = "Revision mode for Container Apps (Single or Multiple)"
  type        = string
  default     = "Single"
}

variable "min_replicas" {
  description = "Minimum number of replicas for the container app"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas for the container app"
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
