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

