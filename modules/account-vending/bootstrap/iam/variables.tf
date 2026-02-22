variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "account_name" {
  description = "Account name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "management_account_id" {
  description = "Management account ID for cross-account access"
  type        = string
}

variable "enable_admin_role" {
  description = "Enable admin role"
  type        = bool
  default     = true
}

variable "enable_readonly_role" {
  description = "Enable read-only role"
  type        = bool
  default     = true
}

variable "enable_developer_role" {
  description = "Enable developer role"
  type        = bool
  default     = true
}

variable "enable_terraform_role" {
  description = "Enable Terraform role"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
