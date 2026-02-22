# OPA EC2 Security Policies
package terraform.controltower.ec2

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.terraform.controltower.helpers

# ============================================================================
# EC2 Instance Metadata Policies
# ============================================================================

# POLICY: EC2 instances must use IMDSv2
deny[msg] {
    instance := helpers.resources_by_type("aws_instance")[_]
    not instance.values.metadata_options[_].http_tokens == "required"
    msg := sprintf("EC2 instance '%s' must use IMDSv2 (http_tokens=required)", [instance.address])
}

# ============================================================================
# EC2 Monitoring Policies
# ============================================================================

# POLICY: EC2 instances must have monitoring enabled
warn[msg] {
    instance := helpers.resources_by_type("aws_instance")[_]
    not instance.values.monitoring
    msg := sprintf("EC2 instance '%s' should have detailed monitoring enabled", [instance.address])
}

# ============================================================================
# EC2 Termination Protection Policies
# ============================================================================

# POLICY: EC2 instances must have termination protection in production
deny[msg] {
    instance := helpers.resources_by_type("aws_instance")[_]
    helpers.is_production(instance)
    not instance.values.disable_api_termination
    msg := sprintf("Production EC2 instance '%s' must have termination protection enabled", [instance.address])
}
