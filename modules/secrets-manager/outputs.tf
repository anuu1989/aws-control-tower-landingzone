# ============================================================================
# Secrets Manager Module - Outputs
# ============================================================================

# ----------------------------------------------------------------------------
# Secret ARNs
# ----------------------------------------------------------------------------

output "notification_emails_secret_arn" {
  description = "ARN of the notification emails secret"
  value       = aws_secretsmanager_secret.notification_emails.arn
}

output "notification_emails_secret_name" {
  description = "Name of the notification emails secret"
  value       = aws_secretsmanager_secret.notification_emails.name
}

output "api_keys_secret_arn" {
  description = "ARN of the API keys secret (if created)"
  value       = var.create_api_keys_secret ? aws_secretsmanager_secret.api_keys[0].arn : null
}

output "api_keys_secret_name" {
  description = "Name of the API keys secret (if created)"
  value       = var.create_api_keys_secret ? aws_secretsmanager_secret.api_keys[0].name : null
}

output "database_credentials_secret_arn" {
  description = "ARN of the database credentials secret (if created)"
  value       = var.create_database_secret ? aws_secretsmanager_secret.database_credentials[0].arn : null
}

output "database_credentials_secret_name" {
  description = "Name of the database credentials secret (if created)"
  value       = var.create_database_secret ? aws_secretsmanager_secret.database_credentials[0].name : null
}

output "webhook_urls_secret_arn" {
  description = "ARN of the webhook URLs secret (if created)"
  value       = var.create_webhook_secret ? aws_secretsmanager_secret.webhook_urls[0].arn : null
}

output "webhook_urls_secret_name" {
  description = "Name of the webhook URLs secret (if created)"
  value       = var.create_webhook_secret ? aws_secretsmanager_secret.webhook_urls[0].name : null
}

# ----------------------------------------------------------------------------
# IAM Policy
# ----------------------------------------------------------------------------

output "secrets_access_policy_arn" {
  description = "ARN of the IAM policy for accessing secrets"
  value       = aws_iam_policy.secrets_access.arn
}

output "secrets_access_policy_name" {
  description = "Name of the IAM policy for accessing secrets"
  value       = aws_iam_policy.secrets_access.name
}

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------

output "secrets_summary" {
  description = "Summary of all secrets created"
  value = {
    notification_emails_secret = aws_secretsmanager_secret.notification_emails.name
    api_keys_secret_created    = var.create_api_keys_secret
    database_secret_created    = var.create_database_secret
    webhook_secret_created     = var.create_webhook_secret
    kms_encrypted              = var.kms_key_id != null
    recovery_window_days       = var.recovery_window_days
  }
}

# ----------------------------------------------------------------------------
# Data Source Outputs (for use in other modules)
# ----------------------------------------------------------------------------

output "notification_emails_data_source" {
  description = "Data source configuration for retrieving notification emails"
  value = {
    secret_id = aws_secretsmanager_secret.notification_emails.id
    example   = "data.aws_secretsmanager_secret_version.notification_emails.secret_string"
  }
}
