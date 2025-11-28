# Variables for Container Apps Terraform configuration

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group (must already exist)"
  type        = string
}

variable "app_name" {
  description = "Application name prefix"
  type        = string
  default     = "ccps-portal"
}

# Container Apps Configuration
variable "container_app_revision_mode" {
  description = "Revision mode for Container Apps (Single or Multiple)"
  type        = string
  default     = "Single"
}

# Single Container App Configuration (contains both frontend and backend)
variable "min_replicas" {
  description = "Minimum number of replicas for the container app (applies to both containers)"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas for the container app (applies to both containers)"
  type        = number
  default     = 10
}

# Backend Container Configuration
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

# Frontend Container Configuration
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

# Database VNet Configuration (optional - for connecting to databases in private VNets)
variable "mysql_vnet_name" {
  description = "Name of the MySQL database VNet (for VNet peering). Leave empty if not using MySQL."
  type        = string
  default     = ""
}

variable "postgresql_vnet_name" {
  description = "Name of the PostgreSQL database VNet (for VNet peering). Leave empty if not using PostgreSQL."
  type        = string
  default     = ""
}

variable "mysql_private_dns_zone_name" {
  description = "Name of the MySQL private DNS zone (for DNS resolution). Leave empty if not using MySQL."
  type        = string
  default     = ""
}

variable "postgresql_private_dns_zone_name" {
  description = "Name of the PostgreSQL private DNS zone (for DNS resolution). Leave empty if not using PostgreSQL."
  type        = string
  default     = ""
}

