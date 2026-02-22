# ============================================================================
# Zero Trust Module Outputs
# ============================================================================

output "vpc_id" {
  description = "Zero Trust VPC ID"
  value       = aws_vpc.zero_trust.id
}

output "vpc_cidr" {
  description = "Zero Trust VPC CIDR block"
  value       = aws_vpc.zero_trust.cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "access_analyzer_arn" {
  description = "IAM Access Analyzer ARN"
  value       = aws_accessanalyzer_analyzer.zero_trust.arn
}

output "mfa_policy_arn" {
  description = "MFA enforcement policy ARN"
  value       = aws_iam_policy.enforce_mfa.arn
}

output "verified_access_instance_id" {
  description = "Verified Access instance ID"
  value       = aws_verifiedaccess_instance.main.id
}

output "flow_logs_group" {
  description = "VPC Flow Logs CloudWatch log group"
  value       = aws_cloudwatch_log_group.flow_logs.name
}

output "session_logs_group" {
  description = "Session Manager logs CloudWatch log group"
  value       = aws_cloudwatch_log_group.session_logs.name
}

output "vpc_endpoints" {
  description = "VPC endpoint IDs"
  value = {
    interface = { for k, v in aws_vpc_endpoint.interface_endpoints : k => v.id }
    s3        = aws_vpc_endpoint.s3.id
    dynamodb  = aws_vpc_endpoint.dynamodb.id
  }
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = var.enable_waf ? aws_wafv2_web_acl.zero_trust[0].arn : null
}

output "privatelink_nlb_arn" {
  description = "PrivateLink Network Load Balancer ARN"
  value       = var.enable_privatelink ? aws_lb.privatelink[0].arn : null
}

output "security_monitoring" {
  description = "Security monitoring resources"
  value = {
    unauthorized_api_calls_alarm = aws_cloudwatch_metric_alarm.unauthorized_api_calls.arn
    no_mfa_login_alarm           = aws_cloudwatch_metric_alarm.no_mfa_console_login.arn
    security_group_changes_rule  = aws_cloudwatch_event_rule.security_group_changes.arn
    iam_changes_rule             = aws_cloudwatch_event_rule.iam_changes.arn
  }
}
