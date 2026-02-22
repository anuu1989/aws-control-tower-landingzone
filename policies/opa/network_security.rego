# OPA Network Security Policies
package terraform.controltower.network

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.terraform.controltower.helpers

# ============================================================================
# VPC Flow Logs Policies
# ============================================================================

# POLICY: VPCs must have flow logs enabled
warn[msg] {
    vpc := helpers.resources_by_type("aws_vpc")[_]
    not has_flow_logs(vpc.values.id)
    msg := sprintf("VPC '%s' should have flow logs enabled", [vpc.address])
}

has_flow_logs(vpc_id) {
    flow_log := helpers.resources_by_type("aws_flow_log")[_]
    flow_log.values.vpc_id == vpc_id
}

# ============================================================================
# Security Group Policies
# ============================================================================

# POLICY: Security groups must not allow unrestricted ingress
deny[msg] {
    sg := helpers.resources_by_type("aws_security_group")[_]
    rule := sg.values.ingress[_]
    rule.cidr_blocks[_] == "0.0.0.0/0"
    rule.from_port == 0
    rule.to_port == 0
    msg := sprintf("Security group '%s' must not allow unrestricted ingress from 0.0.0.0/0", [sg.address])
}

# POLICY: Security groups must not allow SSH from anywhere
deny[msg] {
    sg := helpers.resources_by_type("aws_security_group")[_]
    rule := sg.values.ingress[_]
    rule.cidr_blocks[_] == "0.0.0.0/0"
    rule.from_port == 22
    msg := sprintf("Security group '%s' must not allow SSH (port 22) from 0.0.0.0/0", [sg.address])
}

# POLICY: Security groups must not allow RDP from anywhere
deny[msg] {
    sg := helpers.resources_by_type("aws_security_group")[_]
    rule := sg.values.ingress[_]
    rule.cidr_blocks[_] == "0.0.0.0/0"
    rule.from_port == 3389
    msg := sprintf("Security group '%s' must not allow RDP (port 3389) from 0.0.0.0/0", [sg.address])
}
