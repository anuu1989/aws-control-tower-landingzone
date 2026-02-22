# ============================================================================
# Zero Trust Architecture Module
# ============================================================================
# Implements Zero Trust principles:
# - Never trust, always verify
# - Assume breach
# - Verify explicitly
# - Use least privilege access
# - Segment access
# ============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# Identity and Access Management (IAM) - Zero Trust
# ============================================================================

# IAM Access Analyzer for continuous monitoring
resource "aws_accessanalyzer_analyzer" "zero_trust" {
  analyzer_name = "${var.name_prefix}-zero-trust-analyzer"
  type          = "ORGANIZATION"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-zero-trust-analyzer"
    Purpose = "Zero Trust Access Analysis"
  })
}

# IAM Policy for enforcing MFA
resource "aws_iam_policy" "enforce_mfa" {
  name        = "${var.name_prefix}-enforce-mfa"
  description = "Deny all actions if MFA is not present"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllExceptListedIfNoMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# ============================================================================
# Network Segmentation - Zero Trust
# ============================================================================

# VPC for Zero Trust workloads
resource "aws_vpc" "zero_trust" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-zero-trust-vpc"
  })
}

# Private subnets (no direct internet access)
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.zero_trust.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${var.availability_zones[count.index]}"
    Tier = "Private"
  })
}

# VPC Flow Logs for network monitoring
resource "aws_flow_log" "zero_trust" {
  vpc_id          = aws_vpc.zero_trust.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.name_prefix}-flow-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = var.tags
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.name_prefix}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.name_prefix}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# VPC Endpoints - Private Access (Zero Trust)
# ============================================================================

# Interface endpoints for AWS services (no internet required)
resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = toset(var.interface_endpoints)

  vpc_id              = aws_vpc.zero_trust.id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-${each.value}-endpoint"
    Service = each.value
  })
}

# Gateway endpoints (S3, DynamoDB)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.zero_trust.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.zero_trust.id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-dynamodb-endpoint"
  })
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.zero_trust.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc-endpoints-sg"
  })
}

# Route tables for private subnets
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.zero_trust.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt-${var.availability_zones[count.index]}"
  })
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ============================================================================
# AWS Verified Access - Zero Trust Network Access
# ============================================================================

resource "aws_verifiedaccess_instance" "main" {
  description = "Zero Trust Verified Access Instance"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-verified-access"
  })
}

resource "aws_verifiedaccess_trust_provider" "oidc" {
  count = var.enable_verified_access ? 1 : 0

  policy_reference_name    = "zero-trust-policy"
  trust_provider_type      = "user"
  user_trust_provider_type = "iam-identity-center"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-trust-provider"
  })
}

# ============================================================================
# AWS Systems Manager Session Manager - Secure Access
# ============================================================================

# SSM Document for session logging
resource "aws_ssm_document" "session_manager_prefs" {
  name            = "${var.name_prefix}-session-manager-prefs"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document to configure Session Manager preferences"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = var.session_logs_bucket
      s3KeyPrefix                 = "session-logs/"
      s3EncryptionEnabled         = true
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.session_logs.name
      cloudWatchEncryptionEnabled = true
      kmsKeyId                    = var.kms_key_id
      runAsEnabled                = false
      runAsDefaultUser            = ""
      idleSessionTimeout          = "20"
      maxSessionDuration          = ""
      cloudWatchStreamingEnabled  = true
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "session_logs" {
  name              = "/aws/ssm/${var.name_prefix}-session-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = var.tags
}

# ============================================================================
# AWS PrivateLink - Service-to-Service Communication
# ============================================================================

# Network Load Balancer for PrivateLink
resource "aws_lb" "privatelink" {
  count = var.enable_privatelink ? 1 : 0

  name               = "${var.name_prefix}-privatelink-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.private[*].id

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-privatelink-nlb"
  })
}

# ============================================================================
# AWS Resource Access Manager - Controlled Sharing
# ============================================================================

resource "aws_ram_resource_share" "zero_trust" {
  count = var.enable_ram_sharing ? 1 : 0

  name                      = "${var.name_prefix}-zero-trust-share"
  allow_external_principals = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-zero-trust-share"
  })
}

# ============================================================================
# Security Group - Default Deny
# ============================================================================

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.zero_trust.id

  # No ingress or egress rules - default deny all

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-default-sg-deny-all"
  })
}

# ============================================================================
# Network ACLs - Defense in Depth
# ============================================================================

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.zero_trust.id
  subnet_ids = aws_subnet.private[*].id

  # Allow internal VPC traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  # Allow HTTPS from anywhere (for VPC endpoints)
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-nacl"
  })
}

# ============================================================================
# CloudWatch Alarms - Anomaly Detection
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.name_prefix}-unauthorized-api-calls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "ZeroTrust"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.unauthorized_calls_threshold
  alarm_description   = "Detects unauthorized API calls"
  alarm_actions       = [var.sns_topic_arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "no_mfa_console_login" {
  alarm_name          = "${var.name_prefix}-no-mfa-console-login"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConsoleLoginWithoutMFA"
  namespace           = "ZeroTrust"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Detects console logins without MFA"
  alarm_actions       = [var.sns_topic_arn]

  tags = var.tags
}

# ============================================================================
# EventBridge Rules - Real-time Monitoring
# ============================================================================

resource "aws_cloudwatch_event_rule" "security_group_changes" {
  name        = "${var.name_prefix}-security-group-changes"
  description = "Capture security group changes"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName = [
        "AuthorizeSecurityGroupIngress",
        "AuthorizeSecurityGroupEgress",
        "RevokeSecurityGroupIngress",
        "RevokeSecurityGroupEgress",
        "CreateSecurityGroup",
        "DeleteSecurityGroup"
      ]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "security_group_changes" {
  rule      = aws_cloudwatch_event_rule.security_group_changes.name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn
}

resource "aws_cloudwatch_event_rule" "iam_changes" {
  name        = "${var.name_prefix}-iam-changes"
  description = "Capture IAM policy and role changes"

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["iam.amazonaws.com"]
      eventName = [
        "CreatePolicy",
        "DeletePolicy",
        "CreatePolicyVersion",
        "DeletePolicyVersion",
        "AttachUserPolicy",
        "DetachUserPolicy",
        "AttachRolePolicy",
        "DetachRolePolicy",
        "PutUserPolicy",
        "PutRolePolicy",
        "DeleteUserPolicy",
        "DeleteRolePolicy"
      ]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "iam_changes" {
  rule      = aws_cloudwatch_event_rule.iam_changes.name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn
}

# ============================================================================
# AWS WAF - Application Layer Protection
# ============================================================================

resource "aws_wafv2_web_acl" "zero_trust" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.name_prefix}-zero-trust-waf"
  scope = "REGIONAL"

  default_action {
    block {}
  }

  # Rate limiting
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # Geo blocking
  rule {
    name     = "GeoBlockRule"
    priority = 2

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = var.blocked_countries
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-geo-block"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

# ============================================================================
# AWS Secrets Manager - Secure Credential Storage
# ============================================================================

# Rotation Lambda function role
resource "aws_iam_role" "secrets_rotation" {
  name = "${var.name_prefix}-secrets-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "secrets_rotation" {
  role       = aws_iam_role.secrets_rotation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
