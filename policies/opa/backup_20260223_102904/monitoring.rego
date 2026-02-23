# OPA Monitoring and Logging Policies
package terraform.controltower.monitoring

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.terraform.controltower.helpers

# ============================================================================
# CloudTrail Policies
# ============================================================================

# POLICY: CloudTrail must be enabled
deny[msg] {
    count(helpers.resources_by_type("aws_cloudtrail")) == 0
    msg := "At least one CloudTrail must be configured"
}

# POLICY: CloudTrail must have log file validation enabled
deny[msg] {
    trail := helpers.resources_by_type("aws_cloudtrail")[_]
    not trail.values.enable_log_file_validation
    msg := sprintf("CloudTrail '%s' must have log file validation enabled", [trail.address])
}

# POLICY: CloudTrail must be multi-region
deny[msg] {
    trail := helpers.resources_by_type("aws_cloudtrail")[_]
    not trail.values.is_multi_region_trail
    msg := sprintf("CloudTrail '%s' must be configured as multi-region", [trail.address])
}

# POLICY: CloudTrail must include global service events
deny[msg] {
    trail := helpers.resources_by_type("aws_cloudtrail")[_]
    not trail.values.include_global_service_events
    msg := sprintf("CloudTrail '%s' must include global service events", [trail.address])
}

# ============================================================================
# GuardDuty Policies
# ============================================================================

# POLICY: GuardDuty must be enabled
deny[msg] {
    count(helpers.resources_by_type("aws_guardduty_detector")) == 0
    msg := "GuardDuty detector must be enabled"
}

# POLICY: GuardDuty must be enabled (not disabled)
deny[msg] {
    detector := helpers.resources_by_type("aws_guardduty_detector")[_]
    not detector.values.enable
    msg := sprintf("GuardDuty detector '%s' must be enabled", [detector.address])
}

# ============================================================================
# Security Hub Policies
# ============================================================================

# POLICY: Security Hub must be enabled
warn[msg] {
    count(helpers.resources_by_type("aws_securityhub_account")) == 0
    msg := "Security Hub should be enabled"
}

# POLICY: Security Hub standards must be enabled
warn[msg] {
    count(helpers.resources_by_type("aws_securityhub_standards_subscription")) == 0
    msg := "At least one Security Hub standard should be enabled"
}

# ============================================================================
# Config Policies
# ============================================================================

# POLICY: AWS Config must be enabled
deny[msg] {
    count(helpers.resources_by_type("aws_config_configuration_recorder")) == 0
    msg := "AWS Config configuration recorder must be enabled"
}

# POLICY: Config recorder must record all resources
deny[msg] {
    recorder := helpers.resources_by_type("aws_config_configuration_recorder")[_]
    not recorder.values.recording_group[_].all_supported
    msg := sprintf("Config recorder '%s' must record all supported resources", [recorder.address])
}
