output "log_bucket_id" {
  description = "ID of the log archive S3 bucket"
  value       = aws_s3_bucket.log_archive.id
}

output "log_bucket_arn" {
  description = "ARN of the log archive S3 bucket"
  value       = aws_s3_bucket.log_archive.arn
}

output "access_logs_bucket_id" {
  description = "ID of the access logs S3 bucket"
  value       = aws_s3_bucket.access_logs.id
}

output "cloudtrail_id" {
  description = "ID of the CloudTrail"
  value       = aws_cloudtrail.organization.id
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.organization.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}

output "metric_alarms" {
  description = "Map of CloudWatch metric alarm ARNs"
  value = {
    unauthorized_api_calls  = aws_cloudwatch_metric_alarm.unauthorized_api_calls.arn
    root_account_usage      = aws_cloudwatch_metric_alarm.root_account_usage.arn
    iam_policy_changes      = aws_cloudwatch_metric_alarm.iam_policy_changes.arn
    console_signin_failures = aws_cloudwatch_metric_alarm.console_signin_failures.arn
    vpc_changes             = aws_cloudwatch_metric_alarm.vpc_changes.arn
    security_group_changes  = aws_cloudwatch_metric_alarm.security_group_changes.arn
  }
}
