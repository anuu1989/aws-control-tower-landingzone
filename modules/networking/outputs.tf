output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.arn
}

output "transit_gateway_route_tables" {
  description = "Map of Transit Gateway route table IDs"
  value = {
    shared_services = aws_ec2_transit_gateway_route_table.shared_services.id
    production      = aws_ec2_transit_gateway_route_table.production.id
    non_production  = aws_ec2_transit_gateway_route_table.non_production.id
    inspection      = aws_ec2_transit_gateway_route_table.inspection.id
  }
}

output "inspection_vpc_id" {
  description = "ID of the inspection VPC"
  value       = aws_vpc.inspection.id
}

output "inspection_vpc_cidr" {
  description = "CIDR block of the inspection VPC"
  value       = aws_vpc.inspection.cidr_block
}

output "network_firewall_id" {
  description = "ID of the Network Firewall"
  value       = aws_networkfirewall_firewall.main.id
}

output "network_firewall_arn" {
  description = "ARN of the Network Firewall"
  value       = aws_networkfirewall_firewall.main.arn
}

output "network_firewall_endpoint_ids" {
  description = "Map of Network Firewall endpoint IDs by AZ"
  value = {
    for idx, az in var.availability_zones :
    az => aws_networkfirewall_firewall.main.firewall_status[0].sync_states[idx].attachment[0].endpoint_id
  }
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.inspection[*].id
}

output "nat_gateway_public_ips" {
  description = "List of NAT Gateway public IPs"
  value       = aws_eip.nat[*].public_ip
}

output "dns_firewall_rule_group_id" {
  description = "ID of the DNS Firewall rule group"
  value       = aws_route53_resolver_firewall_rule_group.main.id
}

output "dns_query_log_config_id" {
  description = "ID of the DNS query log configuration"
  value       = aws_route53_resolver_query_log_config.main.id
}

output "inspection_subnets" {
  description = "Map of inspection subnet IDs by type"
  value = {
    firewall = aws_subnet.inspection_firewall[*].id
    tgw      = aws_subnet.inspection_tgw[*].id
    public   = aws_subnet.inspection_public[*].id
  }
}

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch Log Group names"
  value = {
    firewall_alert   = aws_cloudwatch_log_group.firewall_alert.name
    firewall_flow    = aws_cloudwatch_log_group.firewall_flow.name
    vpc_flow_logs    = aws_cloudwatch_log_group.vpc_flow_logs.name
    dns_query_logs   = aws_cloudwatch_log_group.dns_query_logs.name
  }
}

output "network_insights_access_scope_id" {
  description = "ID of the Network Insights Access Scope"
  value       = aws_ec2_network_insights_access_scope.main.id
}
