# OPA Zero Trust Architecture Policies
package terraform.controltower.zerotrust

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.terraform.controltower.helpers

# ============================================================================
# Zero Trust Principle 1: Never Trust, Always Verify
# ============================================================================

# POLICY: All IAM users must have MFA enabled
deny[msg] {
    user := helpers.resources_by_type("aws_iam_user")[_]
    not has_mfa_device(user.address)
    msg := sprintf("IAM user '%s' must have MFA device configured (Zero Trust: Always Verify)", [user.address])
}

has_mfa_device(user_address) {
    mfa := helpers.resources_by_type("aws_iam_user_mfa_device")[_]
    contains(mfa.values.user, user_address)
}

# POLICY: Session Manager must be used instead of SSH/RDP
deny[msg] {
    sg := helpers.resources_by_type("aws_security_group")[_]
    rule := sg.values.ingress[_]
    rule.from_port == 22
    msg := sprintf("Security group '%s' allows SSH access. Use AWS Systems Manager Session Manager instead (Zero Trust: Secure Access)", [sg.address])
}

deny[msg] {
    sg := helpers.resources_by_type("aws_security_group")[_]
    rule := sg.values.ingress[_]
    rule.from_port == 3389
    msg := sprintf("Security group '%s' allows RDP access. Use AWS Systems Manager Session Manager instead (Zero Trust: Secure Access)", [sg.address])
}

# ============================================================================
# Zero Trust Principle 2: Assume Breach
# ============================================================================

# POLICY: VPC Flow Logs must be enabled
deny[msg] {
    vpc := helpers.resources_by_type("aws_vpc")[_]
    not has_flow_logs(vpc.values.id)
    msg := sprintf("VPC '%s' must have Flow Logs enabled (Zero Trust: Assume Breach)", [vpc.address])
}

has_flow_logs(vpc_id) {
    flow_log := helpers.resources_by_type("aws_flow_log")[_]
    flow_log.values.vpc_id == vpc_id
}

# POLICY: GuardDuty must be enabled for threat detection
deny[msg] {
    count(helpers.resources_by_type("aws_guardduty_detector")) == 0
    msg := "GuardDuty must be enabled for continuous threat detection (Zero Trust: Assume Breach)"
}

# POLICY: CloudTrail must be enabled for audit logging
deny[msg] {
    count(helpers.resources_by_type("aws_cloudtrail")) == 0
    msg := "CloudTrail must be enabled for comprehensive audit logging (Zero Trust: Assume Breach)"
}

# ============================================================================
# Zero Trust Principle 3: Verify Explicitly
# ============================================================================

# POLICY: IAM Access Analyzer must be enabled
warn[msg] {
    count(helpers.resources_by_type("aws_accessanalyzer_analyzer")) == 0
    msg := "IAM Access Analyzer should be enabled for continuous access verification (Zero Trust: Verify Explicitly)"
}

# POLICY: All API calls must be logged
deny[msg] {
    trail := helpers.resources_by_type("aws_cloudtrail")[_]
    not trail.values.enable_log_file_validation
    msg := sprintf("CloudTrail '%s' must have log file validation enabled (Zero Trust: Verify Explicitly)", [trail.address])
}

# ============================================================================
# Zero Trust Principle 4: Least Privilege Access
# ============================================================================

# POLICY: IAM policies must not grant wildcard permissions
deny[msg] {
    policy := helpers.resources_by_type("aws_iam_policy")[_]
    statement := policy.values.policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action == "*"
    statement.Resource == "*"
    msg := sprintf("IAM policy '%s' grants wildcard permissions. Use least privilege access (Zero Trust: Least Privilege)", [policy.address])
}

# POLICY: IAM roles must have assume role policy with conditions
warn[msg] {
    role := helpers.resources_by_type("aws_iam_role")[_]
    not has_assume_role_conditions(role)
    msg := sprintf("IAM role '%s' should have conditions in assume role policy (Zero Trust: Least Privilege)", [role.address])
}

has_assume_role_conditions(role) {
    role.values.assume_role_policy.Statement[_].Condition
}

# POLICY: S3 buckets must have bucket policies with least privilege
warn[msg] {
    bucket := helpers.resources_by_type("aws_s3_bucket")[_]
    not has_bucket_policy(bucket.address)
    msg := sprintf("S3 bucket '%s' should have a bucket policy with least privilege access (Zero Trust: Least Privilege)", [bucket.address])
}

has_bucket_policy(bucket_address) {
    policy := helpers.resources_by_type("aws_s3_bucket_policy")[_]
    contains(policy.values.bucket, bucket_address)
}

# ============================================================================
# Zero Trust Principle 5: Segment Access (Micro-segmentation)
# ============================================================================

# POLICY: Resources must be in private subnets
deny[msg] {
    subnet := helpers.resources_by_type("aws_subnet")[_]
    has_internet_gateway_route(subnet)
    not is_public_subnet(subnet)
    msg := sprintf("Subnet '%s' has internet gateway route. Use private subnets with VPC endpoints (Zero Trust: Segment Access)", [subnet.address])
}

has_internet_gateway_route(subnet) {
    route_table := helpers.resources_by_type("aws_route_table")[_]
    route := route_table.values.route[_]
    contains(route.gateway_id, "igw-")
}

is_public_subnet(subnet) {
    contains(lower(subnet.values.tags.Name), "public")
}

is_public_subnet(subnet) {
    contains(lower(subnet.values.tags.Tier), "public")
}

# POLICY: VPC endpoints must be used for AWS services
warn[msg] {
    vpc := helpers.resources_by_type("aws_vpc")[_]
    not has_vpc_endpoints(vpc.values.id)
    msg := sprintf("VPC '%s' should have VPC endpoints for AWS services (Zero Trust: Segment Access)", [vpc.address])
}

has_vpc_endpoints(vpc_id) {
    endpoint := helpers.resources_by_type("aws_vpc_endpoint")[_]
    endpoint.values.vpc_id == vpc_id
}

# POLICY: Security groups must follow default deny principle
deny[msg] {
    sg := helpers.resources_by_type("aws_security_group")[_]
    not sg.values.ingress
    not sg.values.egress
    not is_default_deny_sg(sg)
    msg := sprintf("Security group '%s' must explicitly define rules (Zero Trust: Segment Access)", [sg.address])
}

is_default_deny_sg(sg) {
    contains(sg.values.name, "default")
    count(sg.values.ingress) == 0
    count(sg.values.egress) == 0
}

# POLICY: Network ACLs must be configured for defense in depth
warn[msg] {
    subnet := helpers.resources_by_type("aws_subnet")[_]
    not has_custom_nacl(subnet)
    msg := sprintf("Subnet '%s' should have custom Network ACL for defense in depth (Zero Trust: Segment Access)", [subnet.address])
}

has_custom_nacl(subnet) {
    nacl := helpers.resources_by_type("aws_network_acl")[_]
    subnet.values.id == nacl.values.subnet_ids[_]
}

# ============================================================================
# Zero Trust: Encryption Everywhere
# ============================================================================

# POLICY: All data at rest must be encrypted
deny[msg] {
    volume := helpers.resources_by_type("aws_ebs_volume")[_]
    not volume.values.encrypted
    msg := sprintf("EBS volume '%s' must be encrypted (Zero Trust: Encryption Everywhere)", [volume.address])
}

# POLICY: All data in transit must be encrypted
deny[msg] {
    lb := helpers.resources_by_type("aws_lb_listener")[_]
    lb.values.protocol == "HTTP"
    msg := sprintf("Load balancer listener '%s' must use HTTPS (Zero Trust: Encryption in Transit)", [lb.address])
}

# POLICY: Secrets must be stored in Secrets Manager or Parameter Store
warn[msg] {
    lambda := helpers.resources_by_type("aws_lambda_function")[_]
    lambda.values.environment
    has_hardcoded_secrets(lambda.values.environment)
    msg := sprintf("Lambda function '%s' may have hardcoded secrets. Use AWS Secrets Manager (Zero Trust: Secure Credentials)", [lambda.address])
}

has_hardcoded_secrets(environment) {
    env_var := environment.variables[_]
    contains(lower(env_var), "password")
}

has_hardcoded_secrets(environment) {
    env_var := environment.variables[_]
    contains(lower(env_var), "secret")
}

has_hardcoded_secrets(environment) {
    env_var := environment.variables[_]
    contains(lower(env_var), "api_key")
}

# ============================================================================
# Zero Trust: Continuous Monitoring
# ============================================================================

# POLICY: CloudWatch alarms must be configured for security events
warn[msg] {
    count(helpers.resources_by_type("aws_cloudwatch_metric_alarm")) == 0
    msg := "CloudWatch alarms should be configured for security monitoring (Zero Trust: Continuous Monitoring)"
}

# POLICY: EventBridge rules must be configured for security events
warn[msg] {
    count(helpers.resources_by_type("aws_cloudwatch_event_rule")) == 0
    msg := "EventBridge rules should be configured for real-time security event detection (Zero Trust: Continuous Monitoring)"
}

# POLICY: AWS Config must be enabled for compliance monitoring
deny[msg] {
    count(helpers.resources_by_type("aws_config_configuration_recorder")) == 0
    msg := "AWS Config must be enabled for continuous compliance monitoring (Zero Trust: Continuous Monitoring)"
}

# ============================================================================
# Zero Trust: Identity-Centric Security
# ============================================================================

# POLICY: IAM Identity Center (SSO) should be used
warn[msg] {
    count(helpers.resources_by_type("aws_iam_user")) > 5
    msg := "Consider using AWS IAM Identity Center (SSO) instead of individual IAM users (Zero Trust: Identity-Centric)"
}

# POLICY: Service accounts must use IAM roles, not users
deny[msg] {
    user := helpers.resources_by_type("aws_iam_user")[_]
    is_service_account(user)
    msg := sprintf("Service account '%s' should use IAM role instead of IAM user (Zero Trust: Identity-Centric)", [user.address])
}

is_service_account(user) {
    contains(lower(user.values.name), "service")
}

is_service_account(user) {
    contains(lower(user.values.name), "app")
}

is_service_account(user) {
    contains(lower(user.values.name), "bot")
}

# ============================================================================
# Zero Trust Compliance Summary
# ============================================================================

# Count Zero Trust violations by principle
zero_trust_violations := {
    "never_trust_always_verify": count([msg | msg := deny[_]; contains(msg, "Always Verify")]),
    "assume_breach": count([msg | msg := deny[_]; contains(msg, "Assume Breach")]),
    "verify_explicitly": count([msg | msg := deny[_]; contains(msg, "Verify Explicitly")]),
    "least_privilege": count([msg | msg := deny[_]; contains(msg, "Least Privilege")]),
    "segment_access": count([msg | msg := deny[_]; contains(msg, "Segment Access")]),
    "encryption": count([msg | msg := deny[_]; contains(msg, "Encryption")]),
    "monitoring": count([msg | msg := deny[_]; contains(msg, "Monitoring")]),
    "identity_centric": count([msg | msg := deny[_]; contains(msg, "Identity-Centric")])
}

# Zero Trust compliance score (percentage)
zero_trust_score := score {
    total_checks := 20
    violations := count(deny)
    score := ((total_checks - violations) / total_checks) * 100
}

# Zero Trust compliance status
zero_trust_compliant {
    count(deny) == 0
}
