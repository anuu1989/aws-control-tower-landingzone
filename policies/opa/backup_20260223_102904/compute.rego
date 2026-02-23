# OPA Compute Service Policies
package terraform.controltower.compute

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.terraform.controltower.helpers

# ============================================================================
# Lambda Policies
# ============================================================================

# POLICY: Lambda functions should be in VPC
warn[msg] {
    lambda := helpers.resources_by_type("aws_lambda_function")[_]
    not lambda.values.vpc_config
    msg := sprintf("Lambda function '%s' should be deployed in a VPC", [lambda.address])
}

# POLICY: Lambda functions must have dead letter config
warn[msg] {
    lambda := helpers.resources_by_type("aws_lambda_function")[_]
    not lambda.values.dead_letter_config
    msg := sprintf("Lambda function '%s' should have dead letter queue configured", [lambda.address])
}

# ============================================================================
# Load Balancer Policies
# ============================================================================

# POLICY: ALB must have access logs enabled
warn[msg] {
    alb := helpers.resources_by_type("aws_lb")[_]
    alb.values.load_balancer_type == "application"
    not has_alb_logging(alb.address)
    msg := sprintf("Application Load Balancer '%s' should have access logs enabled", [alb.address])
}

has_alb_logging(alb_address) {
    alb := helpers.resources_by_type("aws_lb")[_]
    alb.address == alb_address
    alb.values.access_logs[_].enabled == true
}

# POLICY: ALB must have deletion protection in production
deny[msg] {
    alb := helpers.resources_by_type("aws_lb")[_]
    helpers.is_production(alb)
    not alb.values.enable_deletion_protection
    msg := sprintf("Production Load Balancer '%s' must have deletion protection enabled", [alb.address])
}
