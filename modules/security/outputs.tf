output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.control_tower.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.control_tower.arn
}

output "kms_alias_name" {
  description = "Name of the KMS key alias"
  value       = aws_kms_alias.control_tower.name
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}

output "securityhub_account_id" {
  description = "Security Hub account ID"
  value       = aws_securityhub_account.main.id
}

output "config_recorder_id" {
  description = "ID of the Config recorder"
  value       = aws_config_configuration_recorder.main.id
}

output "access_analyzer_arn" {
  description = "ARN of the Access Analyzer"
  value       = aws_accessanalyzer_analyzer.organization.arn
}

output "macie_account_id" {
  description = "Macie account ID (if enabled)"
  value       = var.enable_macie ? aws_macie2_account.main[0].id : null
}

output "config_rules" {
  description = "Map of Config rule names"
  value = {
    encrypted_volumes                  = aws_config_config_rule.encrypted_volumes.name
    root_account_mfa                   = aws_config_config_rule.root_account_mfa.name
    iam_password_policy                = aws_config_config_rule.iam_password_policy.name
    s3_bucket_public_read_prohibited   = aws_config_config_rule.s3_bucket_public_read_prohibited.name
    s3_bucket_public_write_prohibited  = aws_config_config_rule.s3_bucket_public_write_prohibited.name
    s3_bucket_ssl_requests_only        = aws_config_config_rule.s3_bucket_ssl_requests_only.name
    s3_bucket_versioning_enabled       = aws_config_config_rule.s3_bucket_versioning_enabled.name
    cloudtrail_enabled                 = aws_config_config_rule.cloudtrail_enabled.name
    rds_encryption_enabled             = aws_config_config_rule.rds_encryption_enabled.name
    vpc_flow_logs_enabled              = aws_config_config_rule.vpc_flow_logs_enabled.name
  }
}

output "security_standards" {
  description = "Enabled Security Hub standards"
  value = {
    cis_aws_foundations = aws_securityhub_standards_subscription.cis.standards_arn
    aws_foundational    = aws_securityhub_standards_subscription.aws_foundational.standards_arn
    pci_dss             = var.enable_pci_dss ? aws_securityhub_standards_subscription.pci_dss[0].standards_arn : null
  }
}
