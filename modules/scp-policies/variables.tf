variable "enabled_policies" {
  description = "List of policies to enable"
  type        = list(string)
  default = [
    # Core Security
    "deny_root_user",
    "require_mfa",
    "restrict_regions",
    "deny_leave_org",
    
    # Logging and Monitoring
    "protect_cloudtrail",
    "protect_security_services",
    
    # Encryption
    "require_encryption",
    "deny_unencrypted_rds",
    "deny_unencrypted_snapshots",
    "require_kms_encryption",
    "deny_unencrypted_secrets",
    "deny_unencrypted_elasticache",
    
    # S3 Security
    "deny_public_s3",
    "deny_s3_public_access",
    "require_s3_ssl",
    
    # EC2 Security
    "restrict_instance_types",
    "require_imdsv2",
    "deny_public_ami",
    
    # Network Security
    "deny_default_vpc",
    
    # IAM Security
    "deny_iam_user_creation",
    "require_iam_password_policy",
    
    # KMS Security
    "deny_kms_key_deletion",
    
    # Database Security
    "deny_public_rds",
    "require_rds_backup",
    
    # Additional Services
    "require_elb_logging",
    "require_tagging"
  ]
}

variable "allowed_regions" {
  description = "List of allowed AWS regions"
  type        = list(string)
}

variable "allowed_instance_types" {
  description = "List of allowed EC2 instance type patterns"
  type        = list(string)
  default     = ["t3.*", "t3a.*", "t4g.*"]
}
