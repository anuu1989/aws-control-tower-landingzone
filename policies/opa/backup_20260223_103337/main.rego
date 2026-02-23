# OPA Main Policy Aggregator
package terraform.controltower

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Import all policy modules
import data.terraform.controltower.encryption
import data.terraform.controltower.s3
import data.terraform.controltower.ec2
import data.terraform.controltower.rds
import data.terraform.controltower.network
import data.terraform.controltower.iam
import data.terraform.controltower.monitoring
import data.terraform.controltower.compute
import data.terraform.controltower.tagging

# ============================================================================
# Aggregate Violations and Warnings
# ============================================================================

# Collect all deny rules from all modules
deny[msg] {
    msg := encryption.deny[_]
}

deny[msg] {
    msg := s3.deny[_]
}

deny[msg] {
    msg := ec2.deny[_]
}

deny[msg] {
    msg := rds.deny[_]
}

deny[msg] {
    msg := network.deny[_]
}

deny[msg] {
    msg := iam.deny[_]
}

deny[msg] {
    msg := monitoring.deny[_]
}

deny[msg] {
    msg := compute.deny[_]
}

# Collect all warn rules from all modules
warn[msg] {
    msg := encryption.warn[_]
}

warn[msg] {
    msg := s3.warn[_]
}

warn[msg] {
    msg := ec2.warn[_]
}

warn[msg] {
    msg := monitoring.warn[_]
}

warn[msg] {
    msg := compute.warn[_]
}

warn[msg] {
    msg := tagging.warn[_]
}

# ============================================================================
# Summary Functions
# ============================================================================

# Count total violations
violation_count := count(deny)

# Count total warnings
warning_count := count(warn)

# Overall compliance status
compliant {
    violation_count == 0
}

# Summary report
summary := {
    "compliant": compliant,
    "violations": violation_count,
    "warnings": warning_count,
    "total_resources": count(input.planned_values.root_module.resources)
}

# Module-specific violation counts
module_violations := {
    "encryption": count(encryption.deny),
    "s3": count(s3.deny),
    "ec2": count(ec2.deny),
    "rds": count(rds.deny),
    "network": count(network.deny),
    "iam": count(iam.deny),
    "monitoring": count(monitoring.deny),
    "compute": count(compute.deny)
}

# Module-specific warning counts
module_warnings := {
    "encryption": count(encryption.warn),
    "s3": count(s3.warn),
    "ec2": count(ec2.warn),
    "monitoring": count(monitoring.warn),
    "compute": count(compute.warn),
    "tagging": count(tagging.warn)
}
