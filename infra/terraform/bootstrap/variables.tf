# Variables for bootstrap Terraform configuration

variable "service_principal_name" {
  description = "Name of the service principal to create"
  type        = string
  default     = "sp-terraform-ccps"
}

variable "environment" {
  description = "Environment name (dev, stage, prod) - used for naming and tagging"
  type        = string
}

variable "terraform_state_storage_account_name" {
  description = "Name of the storage account used for Terraform state backend"
  type        = string
}

variable "terraform_state_resource_group_name" {
  description = "Resource group name containing the Terraform state storage account"
  type        = string
}

variable "assign_user_access_admin" {
  description = "Whether to assign User Access Administrator role (required for Key Vault access policies)"
  type        = bool
  default     = true
}

variable "password_rotation_days" {
  description = "Number of days after which the service principal password should be rotated (0 to disable)"
  type        = number
  default     = 0  # Set to 90 for 90-day rotation, or 0 to disable
}

variable "resource_group_scopes" {
  description = "Map of resource group names to assign Contributor role to (optional, for scope-limited deployments)"
  type        = map(string)
  default     = {}
}

variable "subscription_id" {
  description = "Azure subscription ID (optional, uses current if not specified)"
  type        = string
  default     = ""
}

