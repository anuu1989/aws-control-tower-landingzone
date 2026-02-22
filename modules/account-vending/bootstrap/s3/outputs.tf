# ============================================================================
# S3 Bootstrap Module - Outputs
# ============================================================================
# Outputs for baseline S3 buckets created in the account
# ============================================================================

# ----------------------------------------------------------------------------
# Logs Bucket Outputs
# ----------------------------------------------------------------------------

output "logs_bucket_id" {
  description = "ID of the logs S3 bucket (if created)"
  value       = var.create_logs_bucket ? aws_s3_bucket.logs[0].id : null
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket (if created)"
  value       = var.create_logs_bucket ? aws_s3_bucket.logs[0].arn : null
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket (if created)"
  value       = var.create_logs_bucket ? aws_s3_bucket.logs[0].bucket : null
}

output "logs_bucket_region" {
  description = "Region of the logs S3 bucket (if created)"
  value       = var.create_logs_bucket ? aws_s3_bucket.logs[0].region : null
}

# ----------------------------------------------------------------------------
# Backups Bucket Outputs
# ----------------------------------------------------------------------------

output "backups_bucket_id" {
  description = "ID of the backups S3 bucket (if created)"
  value       = var.create_backups_bucket ? aws_s3_bucket.backups[0].id : null
}

output "backups_bucket_arn" {
  description = "ARN of the backups S3 bucket (if created)"
  value       = var.create_backups_bucket ? aws_s3_bucket.backups[0].arn : null
}

output "backups_bucket_name" {
  description = "Name of the backups S3 bucket (if created)"
  value       = var.create_backups_bucket ? aws_s3_bucket.backups[0].bucket : null
}

output "backups_bucket_region" {
  description = "Region of the backups S3 bucket (if created)"
  value       = var.create_backups_bucket ? aws_s3_bucket.backups[0].region : null
}

# ----------------------------------------------------------------------------
# Data Bucket Outputs
# ----------------------------------------------------------------------------

output "data_bucket_id" {
  description = "ID of the data S3 bucket (if created)"
  value       = var.create_data_bucket ? aws_s3_bucket.data[0].id : null
}

output "data_bucket_arn" {
  description = "ARN of the data S3 bucket (if created)"
  value       = var.create_data_bucket ? aws_s3_bucket.data[0].arn : null
}

output "data_bucket_name" {
  description = "Name of the data S3 bucket (if created)"
  value       = var.create_data_bucket ? aws_s3_bucket.data[0].bucket : null
}

output "data_bucket_region" {
  description = "Region of the data S3 bucket (if created)"
  value       = var.create_data_bucket ? aws_s3_bucket.data[0].region : null
}

# ----------------------------------------------------------------------------
# Summary Outputs
# ----------------------------------------------------------------------------

output "bucket_summary" {
  description = "Summary of all S3 buckets created"
  value = {
    logs_bucket_created    = var.create_logs_bucket
    backups_bucket_created = var.create_backups_bucket
    data_bucket_created    = var.create_data_bucket
    logs_bucket_name       = var.create_logs_bucket ? aws_s3_bucket.logs[0].bucket : null
    backups_bucket_name    = var.create_backups_bucket ? aws_s3_bucket.backups[0].bucket : null
    data_bucket_name       = var.create_data_bucket ? aws_s3_bucket.data[0].bucket : null
    encryption_enabled     = true
    versioning_enabled     = true
    public_access_blocked  = true
  }
}

output "all_bucket_arns" {
  description = "List of all bucket ARNs created"
  value = compact([
    var.create_logs_bucket ? aws_s3_bucket.logs[0].arn : null,
    var.create_backups_bucket ? aws_s3_bucket.backups[0].arn : null,
    var.create_data_bucket ? aws_s3_bucket.data[0].arn : null
  ])
}

output "all_bucket_names" {
  description = "List of all bucket names created"
  value = compact([
    var.create_logs_bucket ? aws_s3_bucket.logs[0].bucket : null,
    var.create_backups_bucket ? aws_s3_bucket.backups[0].bucket : null,
    var.create_data_bucket ? aws_s3_bucket.data[0].bucket : null
  ])
}
