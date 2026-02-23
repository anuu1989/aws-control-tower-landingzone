# OPA IAM Security Policies
package terraform.controltower.iam

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.terraform.controltower.helpers

# ============================================================================
# IAM Policy Policies
# ============================================================================

# POLICY: IAM policies must not allow full admin access
deny[msg] {
    policy := helpers.resources_by_type("aws_iam_policy")[_]
    statement := policy.values.policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action == "*"
    statement.Resource == "*"
    msg := sprintf("IAM policy '%s' must not grant full admin access (*:*)", [policy.address])
}

# ============================================================================
# IAM Role Policies
# ============================================================================

# POLICY: IAM roles must have assume role policy
deny[msg] {
    role := helpers.resources_by_type("aws_iam_role")[_]
    not role.values.assume_role_policy
    msg := sprintf("IAM role '%s' must have an assume role policy", [role.address])
}
