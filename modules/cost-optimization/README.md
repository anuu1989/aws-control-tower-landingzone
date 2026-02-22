# Cost Optimization Module

This module implements AWS cost optimization best practices including budgets, anomaly detection, and cost monitoring.

## Features

- **Monthly Budgets**: Set spending limits with alerts at 80% and 100%
- **Cost Anomaly Detection**: ML-based detection of unusual spending patterns
- **Cost Allocation**: Categorize costs by environment (Production/Non-Production)
- **CloudWatch Dashboard**: Visualize costs and trends
- **Quarterly Budgets**: Optional quarterly budget tracking

## Usage

```terraform
module "cost_optimization" {
  source = "./modules/cost-optimization"

  name_prefix          = "control-tower"
  region               = "ap-southeast-2"
  monthly_budget_limit = 5000

  notification_emails = [
    "finance@example.com",
    "ops@example.com"
  ]

  sns_topic_arn = aws_sns_topic.operational_notifications.arn

  anomaly_threshold = 100  # Alert on $100+ anomalies

  production_account_ids = [
    "123456789012"
  ]

  nonprod_account_ids = [
    "234567890123",
    "345678901234"
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | - | yes |
| region | AWS region | string | - | yes |
| monthly_budget_limit | Monthly budget limit in USD | number | 5000 | no |
| notification_emails | Email addresses for alerts | list(string) | - | yes |
| sns_topic_arn | SNS topic for notifications | string | - | yes |
| anomaly_threshold | Dollar threshold for anomaly alerts | number | 100 | no |
| anomaly_alert_frequency | Frequency of anomaly alerts | string | "DAILY" | no |
| production_account_ids | Production account IDs | list(string) | [] | no |
| nonprod_account_ids | Non-production account IDs | list(string) | [] | no |
| enable_quarterly_budget | Enable quarterly budget | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| monthly_budget_name | Name of the monthly budget |
| anomaly_monitor_arn | ARN of the cost anomaly monitor |
| cost_dashboard_url | URL to the cost monitoring dashboard |

## Cost Considerations

This module itself has minimal cost:
- AWS Budgets: Free (first 2 budgets)
- Cost Anomaly Detection: Free
- CloudWatch Dashboard: Free
- Cost Explorer API calls: $0.01 per request (minimal)

## Best Practices

1. **Set Realistic Budgets**: Base limits on historical spending + growth
2. **Review Alerts**: Investigate all budget alerts promptly
3. **Update Regularly**: Adjust budgets quarterly based on actual usage
4. **Tag Resources**: Ensure all resources are properly tagged for cost allocation
5. **Monitor Trends**: Review cost dashboard weekly

## Alerts

### Budget Alerts
- **80% Threshold**: Warning - review spending
- **100% Actual**: Critical - immediate action required
- **100% Forecasted**: Warning - projected to exceed budget

### Anomaly Alerts
- Triggered when spending deviates from normal patterns
- ML-based detection improves over time
- Configurable threshold (default: $100)

## Integration

This module integrates with:
- SNS for notifications
- CloudWatch for dashboards
- Cost Explorer for analysis
- AWS Budgets for tracking

## Troubleshooting

### Budget Not Creating
- Ensure you have permissions for `budgets:CreateBudget`
- Verify email addresses are valid
- Check SNS topic exists and has correct permissions

### No Anomaly Alerts
- Anomaly detection requires 10+ days of data
- Ensure spending patterns are established
- Check SNS topic subscriptions are confirmed

### Dashboard Not Showing Data
- Billing metrics are only available in us-east-1
- Wait 24 hours for initial data
- Verify CloudWatch permissions

## References

- [AWS Budgets Documentation](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- [Cost Anomaly Detection](https://docs.aws.amazon.com/cost-management/latest/userguide/manage-ad.html)
- [Cost Allocation Tags](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html)
