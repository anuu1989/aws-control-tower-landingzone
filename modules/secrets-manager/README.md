# Secrets Manager Module

This module manages AWS Secrets Manager secrets for storing sensitive configuration values used by the Control Tower deployment.

## Features

- Centralized secrets storage
- KMS encryption
- Automatic rotation support (for database credentials)
- Access logging and monitoring
- Version management
- IAM policy for controlled access

## Secrets Created

### 1. Notification Emails (Always Created)
Stores email addresses for different notification types:
- Security notifications
- Operational notifications
- Compliance notifications

### 2. API Keys (Optional)
Stores API keys for external integrations (Slack, monitoring tools, etc.)

### 3. Database Credentials (Optional)
Stores database credentials with support for automatic rotation

### 4. Webhook URLs (Optional)
Stores webhook URLs for Slack, Microsoft Teams, and other notification services

## Usage

### Basic Usage

```terraform
module "secrets_manager" {
  source = "./modules/secrets-manager"

  name_prefix = "control-tower"
  kms_key_id  = module.security.kms_key_id

  # Notification emails (required)
  security_notification_emails    = ["security@example.com"]
  operational_notification_emails = ["ops@example.com"]
  compliance_notification_emails  = ["compliance@example.com"]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### With Optional Secrets

```terraform
module "secrets_manager" {
  source = "./modules/secrets-manager"

  name_prefix = "control-tower"
  kms_key_id  = module.security.kms_key_id

  # Notification emails
  security_notification_emails    = ["security@example.com"]
  operational_notification_emails = ["ops@example.com"]
  compliance_notification_emails  = ["compliance@example.com"]

  # API Keys
  create_api_keys_secret = true
  api_keys = {
    datadog_api_key = "your-datadog-api-key"
    pagerduty_key   = "your-pagerduty-key"
  }

  # Webhook URLs
  create_webhook_secret = true
  slack_webhook_url     = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  teams_webhook_url     = "https://outlook.office.com/webhook/YOUR/WEBHOOK/URL"

  # Monitoring
  alarm_sns_topic_arn = aws_sns_topic.security.arn

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Retrieving Secrets in Terraform

### Notification Emails

```terraform
# Retrieve notification emails
data "aws_secretsmanager_secret_version" "notification_emails" {
  secret_id = module.secrets_manager.notification_emails_secret_name
}

locals {
  notification_emails = jsondecode(data.aws_secretsmanager_secret_version.notification_emails.secret_string)
  security_emails     = local.notification_emails.security_emails
  operational_emails  = local.notification_emails.operational_emails
}

# Use in SNS topic subscription
resource "aws_sns_topic_subscription" "security_email" {
  for_each = toset(local.security_emails)

  topic_arn = aws_sns_topic.security.arn
  protocol  = "email"
  endpoint  = each.value
}
```

### API Keys

```terraform
data "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = module.secrets_manager.api_keys_secret_name
}

locals {
  api_keys = jsondecode(data.aws_secretsmanager_secret_version.api_keys.secret_string)
}

# Use in Lambda environment variables
resource "aws_lambda_function" "monitoring" {
  # ... other configuration ...

  environment {
    variables = {
      DATADOG_API_KEY = local.api_keys.datadog_api_key
    }
  }
}
```

## Retrieving Secrets in AWS CLI

```bash
# Get notification emails
aws secretsmanager get-secret-value \
  --secret-id control-tower/notification-emails \
  --query SecretString \
  --output text | jq .

# Get API keys
aws secretsmanager get-secret-value \
  --secret-id control-tower/api-keys \
  --query SecretString \
  --output text | jq .
```

## Retrieving Secrets in Python (Lambda)

```python
import boto3
import json

def get_secret(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

# Get notification emails
emails = get_secret('control-tower/notification-emails')
security_emails = emails['security_emails']

# Get API keys
api_keys = get_secret('control-tower/api-keys')
datadog_key = api_keys['datadog_api_key']
```

## Security Best Practices

1. **KMS Encryption**: Always use KMS encryption for secrets
2. **Least Privilege**: Use the provided IAM policy for controlled access
3. **Rotation**: Enable automatic rotation for database credentials
4. **Monitoring**: Monitor secret access patterns with CloudWatch alarms
5. **Recovery Window**: Set appropriate recovery window (7-30 days)
6. **Access Logging**: Enable CloudTrail logging for secret access

## IAM Policy

The module creates an IAM policy that grants read access to all secrets. Attach this policy to roles that need access:

```terraform
resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.lambda.name
  policy_arn = module.secrets_manager.secrets_access_policy_arn
}
```

## Monitoring

The module includes CloudWatch monitoring for:
- Secret access count
- Excessive access alarm (configurable threshold)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for secret names | string | "control-tower" | no |
| kms_key_id | KMS key ID for encryption | string | null | no |
| recovery_window_days | Recovery window in days | number | 30 | no |
| security_notification_emails | Security notification emails | list(string) | [] | no |
| operational_notification_emails | Operational notification emails | list(string) | [] | no |
| compliance_notification_emails | Compliance notification emails | list(string) | [] | no |
| create_api_keys_secret | Create API keys secret | bool | false | no |
| api_keys | Map of API keys | map(string) | {} | no |
| create_database_secret | Create database secret | bool | false | no |
| create_webhook_secret | Create webhook secret | bool | false | no |
| slack_webhook_url | Slack webhook URL | string | "" | no |
| teams_webhook_url | Teams webhook URL | string | "" | no |
| secret_access_threshold | Access alarm threshold | number | 100 | no |
| alarm_sns_topic_arn | SNS topic for alarms | string | null | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| notification_emails_secret_arn | ARN of notification emails secret |
| notification_emails_secret_name | Name of notification emails secret |
| api_keys_secret_arn | ARN of API keys secret |
| database_credentials_secret_arn | ARN of database credentials secret |
| webhook_urls_secret_arn | ARN of webhook URLs secret |
| secrets_access_policy_arn | ARN of IAM access policy |
| secrets_summary | Summary of all secrets |

## Cost Considerations

- **Secrets Manager**: $0.40 per secret per month
- **API Calls**: $0.05 per 10,000 API calls
- **KMS**: Additional cost if using customer-managed keys

Example monthly cost for 4 secrets: ~$1.60/month

## Examples

See `examples/secrets-manager/` for complete examples.
