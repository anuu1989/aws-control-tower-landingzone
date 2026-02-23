# OPA Tagging Policies
package terraform.controltower.tagging

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.terraform.controltower.helpers

# ============================================================================
# Required Tags Configuration
# ============================================================================

required_tags := ["Environment", "ManagedBy", "Project"]

# ============================================================================
# Tagging Policies
# ============================================================================

# POLICY: Resources must have required tags
warn[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.values.tags
    missing := helpers.missing_tags(resource, required_tags)
    count(missing) > 0
    msg := sprintf("Resource '%s' is missing required tags: %v", [resource.address, missing])
}
