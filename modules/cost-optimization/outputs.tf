# ============================================================================
# Cost Optimization Module - Outputs
# ============================================================================

output "monthly_budget_name" {
  description = "Name of the monthly budget"
  value       = aws_budgets_budget.monthly.name
}

output "monthly_budget_id" {
  description = "ID of the monthly budget"
  value       = aws_budgets_budget.monthly.id
}

output "anomaly_monitor_arn" {
  description = "ARN of the cost anomaly monitor"
  value       = aws_ce_anomaly_monitor.service_monitor.arn
}

output "anomaly_subscription_arn" {
  description = "ARN of the cost anomaly subscription"
  value       = aws_ce_anomaly_subscription.anomaly_alerts.arn
}

output "cost_category_arn" {
  description = "ARN of the cost category"
  value       = aws_ce_cost_category.environment.arn
}

output "cost_dashboard_name" {
  description = "Name of the CloudWatch cost monitoring dashboard"
  value       = aws_cloudwatch_dashboard.cost_monitoring.dashboard_name
}

output "cost_dashboard_url" {
  description = "URL to the CloudWatch cost monitoring dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.cost_monitoring.dashboard_name}"
}
