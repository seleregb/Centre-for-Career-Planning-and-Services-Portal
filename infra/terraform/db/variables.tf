# Variables for Database Terraform configuration

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
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

# PostgreSQL Database Configuration
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

variable "postgresql_location" {
  description = "Azure region for PostgreSQL Flexible Server (eastus2)"
  type        = string
  default     = "eastus2"
}

# MySQL Database Configuration
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

variable "mysql_location" {
  description = "Azure region for MySQL Flexible Server (eastus)"
  type        = string
  default     = "eastus"
}

