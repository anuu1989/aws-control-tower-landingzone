terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# Transit Gateway - Hub for Multi-Account Networking
# ============================================================================

resource "aws_ec2_transit_gateway" "main" {
  description                     = "Control Tower Transit Gateway"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support               = "enable"
  amazon_side_asn                = var.transit_gateway_asn

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-tgw"
    }
  )
}

# Transit Gateway Route Tables
resource "aws_ec2_transit_gateway_route_table" "shared_services" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-tgw-rt-shared-services"
    }
  )
}

resource "aws_ec2_transit_gateway_route_table" "production" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-tgw-rt-production"
    }
  )
}

resource "aws_ec2_transit_gateway_route_table" "non_production" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-tgw-rt-non-production"
    }
  )
}

resource "aws_ec2_transit_gateway_route_table" "inspection" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-tgw-rt-inspection"
    }
  )
}

# ============================================================================
# Inspection VPC - Network Firewall and Traffic Inspection
# ============================================================================

resource "aws_vpc" "inspection" {
  cidr_block           = var.inspection_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-inspection-vpc"
      Type = "Inspection"
    }
  )
}

# Internet Gateway for Inspection VPC
resource "aws_internet_gateway" "inspection" {
  vpc_id = aws_vpc.inspection.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-inspection-igw"
    }
  )
}

# Inspection VPC Subnets (3 AZs)
resource "aws_subnet" "inspection_firewall" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.inspection.id
  cidr_block        = cidrsubnet(var.inspection_vpc_cidr, 4, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-inspection-firewall-${var.availability_zones[count.index]}"
      Type = "Firewall"
    }
  )
}

resource "aws_subnet" "inspection_tgw" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.inspection.id
  cidr_block        = cidrsubnet(var.inspection_vpc_cidr, 4, count.index + 3)
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-inspection-tgw-${var.availability_zones[count.index]}"
      Type = "TransitGateway"
    }
  )
}

resource "aws_subnet" "inspection_public" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.inspection.id
  cidr_block        = cidrsubnet(var.inspection_vpc_cidr, 4, count.index + 6)
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-inspection-public-${var.availability_zones[count.index]}"
      Type = "Public"
    }
  )
}

# NAT Gateways for Inspection VPC
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nat-eip-${var.availability_zones[count.index]}"
    }
  )
}

resource "aws_nat_gateway" "inspection" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.inspection_public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nat-${var.availability_zones[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.inspection]
}

# ============================================================================
# AWS Network Firewall
# ============================================================================

# Firewall Policy
resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${var.name_prefix}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateless_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.stateless_allow_icmp.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_domain_allow.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_domain_deny.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_threat_signature.arn
    }

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = var.tags
}

# Stateless Rule Group - Allow ICMP
resource "aws_networkfirewall_rule_group" "stateless_allow_icmp" {
  capacity = 10
  name     = "${var.name_prefix}-stateless-allow-icmp"
  type     = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols = [1] # ICMP

              source {
                address_definition = "0.0.0.0/0"
              }

              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }

  tags = var.tags
}

# Stateful Rule Group - Domain Allow List
resource "aws_networkfirewall_rule_group" "stateful_domain_allow" {
  capacity = 100
  name     = "${var.name_prefix}-stateful-domain-allow"
  type     = "STATEFUL"

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.inspection_vpc_cidr]
        }
      }
    }

    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets = concat(
          var.allowed_domains,
          [
            ".amazonaws.com",
            ".aws.amazon.com",
            ".cloudfront.net"
          ]
        )
      }
    }
  }

  tags = var.tags
}

# Stateful Rule Group - Domain Deny List
resource "aws_networkfirewall_rule_group" "stateful_domain_deny" {
  capacity = 100
  name     = "${var.name_prefix}-stateful-domain-deny"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = var.denied_domains
      }
    }
  }

  tags = var.tags
}

# Stateful Rule Group - Threat Signatures
resource "aws_networkfirewall_rule_group" "stateful_threat_signature" {
  capacity = 1000
  name     = "${var.name_prefix}-stateful-threat-signatures"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<-EOT
        drop tcp any any -> any any (msg:"Block known malware C2"; content:"malware"; sid:1000001; rev:1;)
        drop tcp any any -> any 4444 (msg:"Block Metasploit default port"; sid:1000002; rev:1;)
        drop tcp any any -> any 5555 (msg:"Block common backdoor port"; sid:1000003; rev:1;)
        alert tcp any any -> any 22 (msg:"SSH connection attempt"; sid:1000004; rev:1;)
        alert tcp any any -> any 3389 (msg:"RDP connection attempt"; sid:1000005; rev:1;)
      EOT
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = var.tags
}

# Network Firewall
resource "aws_networkfirewall_firewall" "main" {
  name                = "${var.name_prefix}-network-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = aws_vpc.inspection.id

  dynamic "subnet_mapping" {
    for_each = aws_subnet.inspection_firewall
    content {
      subnet_id = subnet_mapping.value.id
    }
  }

  tags = var.tags
}

# Firewall Logging Configuration
resource "aws_networkfirewall_logging_configuration" "main" {
  firewall_arn = aws_networkfirewall_firewall.main.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_alert.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_flow.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }

    log_destination_config {
      log_destination = {
        bucketName = var.log_bucket_name
        prefix     = "network-firewall"
      }
      log_destination_type = "S3"
      log_type             = "FLOW"
    }
  }
}

# CloudWatch Log Groups for Firewall
resource "aws_cloudwatch_log_group" "firewall_alert" {
  name              = "/aws/network-firewall/${var.name_prefix}/alert"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "firewall_flow" {
  name              = "/aws/network-firewall/${var.name_prefix}/flow"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = var.tags
}

# ============================================================================
# VPC Flow Logs for Inspection VPC
# ============================================================================

resource "aws_flow_log" "inspection_vpc" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.inspection.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-inspection-vpc-flow-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${var.name_prefix}-inspection"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = var.tags
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.name_prefix}-vpc-flow-logs-role"

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
  name = "flow-logs-policy"
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
# Route Tables for Inspection VPC
# ============================================================================

# Firewall Subnet Route Tables
resource "aws_route_table" "inspection_firewall" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.inspection.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-inspection-firewall-rt-${var.availability_zones[count.index]}"
    }
  )
}

resource "aws_route_table_association" "inspection_firewall" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.inspection_firewall[count.index].id
  route_table_id = aws_route_table.inspection_firewall[count.index].id
}

# TGW Subnet Route Tables
resource "aws_route_table" "inspection_tgw" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.inspection.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-inspection-tgw-rt-${var.availability_zones[count.index]}"
    }
  )
}

resource "aws_route_table_association" "inspection_tgw" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.inspection_tgw[count.index].id
  route_table_id = aws_route_table.inspection_tgw[count.index].id
}

# Public Subnet Route Tables
resource "aws_route_table" "inspection_public" {
  vpc_id = aws_vpc.inspection.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inspection.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-inspection-public-rt"
    }
  )
}

resource "aws_route_table_association" "inspection_public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.inspection_public[count.index].id
  route_table_id = aws_route_table.inspection_public.id
}

# ============================================================================
# Transit Gateway Attachment for Inspection VPC
# ============================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "inspection" {
  subnet_ids         = aws_subnet.inspection_tgw[*].id
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.inspection.id

  appliance_mode_support = "enable"
  dns_support            = "enable"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-inspection-tgw-attachment"
    }
  )
}

resource "aws_ec2_transit_gateway_route_table_association" "inspection" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
}

# ============================================================================
# Route 53 Resolver (DNS Firewall)
# ============================================================================

resource "aws_route53_resolver_firewall_rule_group" "main" {
  name = "${var.name_prefix}-dns-firewall-rules"

  tags = var.tags
}

# Block known malicious domains
resource "aws_route53_resolver_firewall_domain_list" "blocked_domains" {
  name    = "${var.name_prefix}-blocked-domains"
  domains = var.dns_blocked_domains

  tags = var.tags
}

resource "aws_route53_resolver_firewall_rule" "block_malicious" {
  name                    = "block-malicious-domains"
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.blocked_domains.id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.main.id
  priority                = 100

  block_override_dns_type = "CQNAME"
}

# Allow trusted domains
resource "aws_route53_resolver_firewall_domain_list" "allowed_domains" {
  name    = "${var.name_prefix}-allowed-domains"
  domains = var.dns_allowed_domains

  tags = var.tags
}

resource "aws_route53_resolver_firewall_rule" "allow_trusted" {
  name                    = "allow-trusted-domains"
  action                  = "ALLOW"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.allowed_domains.id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.main.id
  priority                = 200
}

# Associate DNS Firewall with Inspection VPC
resource "aws_route53_resolver_firewall_rule_group_association" "inspection" {
  name                   = "${var.name_prefix}-inspection-dns-firewall"
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.main.id
  priority               = 101
  vpc_id                 = aws_vpc.inspection.id

  tags = var.tags
}

# DNS Query Logging
resource "aws_route53_resolver_query_log_config" "main" {
  name            = "${var.name_prefix}-dns-query-logs"
  destination_arn = aws_cloudwatch_log_group.dns_query_logs.arn

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "dns_query_logs" {
  name              = "/aws/route53/resolver/${var.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = var.tags
}

resource "aws_route53_resolver_query_log_config_association" "inspection" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.main.id
  resource_id                  = aws_vpc.inspection.id
}

# ============================================================================
# Network Access Analyzer
# ============================================================================

resource "aws_ec2_network_insights_access_scope" "main" {
  match_paths {
    source {
      resource_statement {
        resource_types = ["AWS::EC2::InternetGateway"]
      }
    }

    destination {
      resource_statement {
        resource_types = ["AWS::EC2::Instance"]
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-network-access-scope"
    }
  )
}

resource "aws_ec2_network_insights_access_scope_analysis" "main" {
  network_insights_access_scope_id = aws_ec2_network_insights_access_scope.main.id

  tags = var.tags
}

# ============================================================================
# CloudWatch Alarms for Network Monitoring
# ============================================================================

# High NAT Gateway Bandwidth
resource "aws_cloudwatch_metric_alarm" "nat_gateway_bandwidth" {
  count = length(var.availability_zones)

  alarm_name          = "${var.name_prefix}-nat-gateway-bandwidth-${var.availability_zones[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BytesOutToDestination"
  namespace           = "AWS/NATGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.nat_gateway_bandwidth_threshold
  alarm_description   = "NAT Gateway bandwidth exceeds threshold"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    NatGatewayId = aws_nat_gateway.inspection[count.index].id
  }

  tags = var.tags
}

# Network Firewall Packet Drop
resource "aws_cloudwatch_metric_alarm" "firewall_packet_drop" {
  alarm_name          = "${var.name_prefix}-firewall-packet-drop"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DroppedPackets"
  namespace           = "AWS/NetworkFirewall"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.firewall_packet_drop_threshold
  alarm_description   = "Network Firewall dropping excessive packets"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    FirewallName = aws_networkfirewall_firewall.main.name
  }

  tags = var.tags
}
