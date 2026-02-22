variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
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

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed for SSH access"
  type        = list(string)
  default     = []
}

variable "allowed_https_cidrs" {
  description = "CIDRs allowed for HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
