variable "account_name" {
  description = "Account name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 365
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "log_bucket_name" {
  description = "Central S3 bucket for logs"
  type        = string
}

variable "management_account" {
  description = "Management account ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
