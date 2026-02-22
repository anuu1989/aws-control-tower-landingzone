# ============================================================================
# Security Bootstrap Module - Outputs
# ============================================================================
# Outputs for security services configured in the account
# ============================================================================

# ----------------------------------------------------------------------------
# GuardDuty Outputs
# ----------------------------------------------------------------------------

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector (if enabled)"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "guardduty_enabled" {
  description = "Whether GuardDuty is enabled"
  value       = var.enable_guardduty
}

# ----------------------------------------------------------------------------
# Security Hub Outputs
# ----------------------------------------------------------------------------

output "securityhub_account_id" {
  description = "Security Hub account ID (if enabled)"
  value       = var.enable_securityhub ? aws_securityhub_account.main[0].id : null
}

output "securityhub_enabled" {
  description = "Whether Security Hub is enabled"
  value       = var.enable_securityhub
}

output "securityhub_standards" {
  description = "List of Security Hub standards enabled"
  value = var.enable_securityhub ? [
    "CIS AWS Foundations Benchmark v1.2.0",
    "AWS Foundational Security Best Practices v1.0.0"
  ] : []
}

# ----------------------------------------------------------------------------
# AWS Config Outputs
# ----------------------------------------------------------------------------

output "config_recorder_id" {
  description = "ID of the AWS Config recorder (if enabled)"
  value       = var.enable_config ? aws_config_configuration_recorder.main[0].id : null
}

output "config_recorder_name" {
  description = "Name of the AWS Config recorder (if enabled)"
  value       = var.enable_config ? aws_config_configuration_recorder.main[0].name : null
}

output "config_enabled" {
  description = "Whether AWS Config is enabled"
  value       = var.enable_config
}

output "config_role_arn" {
  description = "ARN of the IAM role used by AWS Config (if enabled)"
  value       = var.enable_config ? aws_iam_role.config[0].arn : null
}

# ----------------------------------------------------------------------------
# Access Analyzer Outputs
# ----------------------------------------------------------------------------

output "access_analyzer_arn" {
  description = "ARN of the IAM Access Analyzer (if enabled)"
  value       = var.enable_access_analyzer ? aws_accessanalyzer_analyzer.main[0].arn : null
}

output "access_analyzer_name" {
  description = "Name of the IAM Access Analyzer (if enabled)"
  value       = var.enable_access_analyzer ? aws_accessanalyzer_analyzer.main[0].analyzer_name : null
}

output "access_analyzer_enabled" {
  description = "Whether IAM Access Analyzer is enabled"
  value       = var.enable_access_analyzer
}

# ----------------------------------------------------------------------------
# Encryption Outputs
# ----------------------------------------------------------------------------

output "ebs_encryption_enabled" {
  description = "Whether EBS encryption by default is enabled"
  value       = true
}

# ----------------------------------------------------------------------------
# S3 Security Outputs
# ----------------------------------------------------------------------------

output "s3_public_access_blocked" {
  description = "Whether S3 public access is blocked at account level"
  value       = true
}

output "s3_block_public_acls" {
  description = "Whether S3 public ACLs are blocked"
  value       = aws_s3_account_public_access_block.main.block_public_acls
}

output "s3_block_public_policy" {
  description = "Whether S3 public policies are blocked"
  value       = aws_s3_account_public_access_block.main.block_public_policy
}

# ----------------------------------------------------------------------------
# Summary Output
# ----------------------------------------------------------------------------

output "security_summary" {
  description = "Summary of security services enabled in the account"
  value = {
    account_id           = var.account_id
    account_name         = var.account_name
    environment          = var.environment
    guardduty_enabled    = var.enable_guardduty
    securityhub_enabled  = var.enable_securityhub
    config_enabled       = var.enable_config
    access_analyzer_enabled = var.enable_access_analyzer
    ebs_encryption       = true
    s3_public_access_blocked = true
  }
}
