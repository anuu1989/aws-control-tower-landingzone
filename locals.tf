# ============================================================================
# Local Values - Computed Values and Data Transformations
# ============================================================================
#
# Purpose:
#   This file contains local values that transform input variables into
#   formats needed by modules, perform complex data manipulations, and
#   define reusable values across the configuration.
#
# Key Responsibilities:
#   1. Common Tags: Standardized tags applied to all resources
#   2. SCP Attachments: Complex mapping of policies to OUs and root
#   3. Validation: Ensure configuration consistency before deployment
#
# Design Patterns:
#   - DRY (Don't Repeat Yourself): Define once, use everywhere
#   - Validation: Catch configuration errors early
#   - Flexibility: Support extensible OU structure
#
# ============================================================================

locals {
  # ============================================================================
  # Environment and Project Configuration
  # ============================================================================
  # Simple aliases for frequently used values to improve readability

  environment = var.environment
  project     = var.project_name

  # ============================================================================
  # Common Tags - Applied to All Resources
  # ============================================================================
  # Standardized tagging strategy for:
  # - Cost allocation and tracking
  # - Resource ownership and management
  # - Compliance and audit requirements
  # - Automation and lifecycle management
  #
  # Tags are merged with user-provided default_tags, allowing customization
  # while ensuring core tags are always present.

  common_tags = merge(
    var.default_tags, # User-provided tags from variables
    {
      ManagedBy   = "Terraform"        # Identifies IaC-managed resources
      Environment = var.environment    # Environment classification (prod/nonprod)
      Project     = var.project_name   # Project/application identifier
      Repository  = var.repository_url # Source code repository for traceability
    }
  )

  # ============================================================================
  # Root Level SCP Attachments
  # ============================================================================
  # Creates a map of SCP policies to attach to the root organizational unit.
  # Root-level policies apply to ALL accounts in the organization, providing
  # organization-wide guardrails that cannot be bypassed.
  #
  # Use Cases:
  # - Prevent root user usage across all accounts
  # - Enforce encryption requirements organization-wide
  # - Restrict operations to allowed regions
  # - Protect critical security services (CloudTrail, Config, etc.)
  #
  # Map Structure:
  #   Key: "root_<policy_name>" (e.g., "root_deny_root_user")
  #   Value: { policy_id, target_id }

  root_attachments = {
    for policy in var.root_scp_policies :
    "root_${policy}" => {
      policy_id = module.scp_policies.policy_ids[policy] # SCP policy ID
      target_id = module.control_tower.root_id           # Root OU ID
    }
  }

  # ============================================================================
  # Organizational Unit SCP Attachments
  # ============================================================================
  # Creates a map of SCP policies to attach to specific organizational units.
  # OU-level policies apply only to accounts within that OU, allowing
  # environment-specific controls (e.g., stricter policies for production).
  #
  # This is a complex transformation that:
  # 1. Iterates through each OU and its assigned policies
  # 2. Creates a unique key for each OU-policy combination
  # 3. Maps policy IDs to OU IDs
  # 4. Flattens nested maps into a single map
  #
  # Example Input (var.ou_scp_policies):
  #   {
  #     nonprod = ["require_mfa", "restrict_instance_types"]
  #     prod    = ["require_mfa"]
  #   }
  #
  # Example Output (local.ou_attachments):
  #   {
  #     "nonprod_require_mfa"            = { policy_id = "p-xxx", target_id = "ou-xxx" }
  #     "nonprod_restrict_instance_types" = { policy_id = "p-yyy", target_id = "ou-xxx" }
  #     "prod_require_mfa"               = { policy_id = "p-xxx", target_id = "ou-yyy" }
  #   }
  #
  # Map Structure:
  #   Key: "<ou_key>_<policy_name>" (e.g., "nonprod_require_mfa")
  #   Value: { policy_id, target_id }

  ou_attachments = merge([
    for ou_key, policies in var.ou_scp_policies : {
      for policy in policies :
      "${ou_key}_${policy}" => {
        policy_id = module.scp_policies.policy_ids[policy]     # SCP policy ID
        target_id = module.organizational_units.ou_ids[ou_key] # OU ID
      }
    }
  ]...) # The ... operator flattens the list of maps into a single map

  # ============================================================================
  # Merged Policy Attachments
  # ============================================================================
  # Combines root-level and OU-level attachments into a single map.
  # This unified map is passed to the scp-attachments module, which creates
  # all policy attachments in a single operation.
  #
  # Benefits:
  # - Single source of truth for all attachments
  # - Simplified module interface
  # - Easier to validate and debug
  #
  # Total Attachments = Root Policies + (OUs × Policies per OU)

  policy_attachments = merge(
    local.root_attachments, # Organization-wide policies
    local.ou_attachments    # OU-specific policies
  )

  # ============================================================================
  # Validation Data - OU Key Consistency Check
  # ============================================================================
  # Validates that all OU keys referenced in ou_scp_policies actually exist
  # in the organizational_units variable. This prevents runtime errors from
  # referencing non-existent OUs.
  #
  # Validation Logic:
  # 1. Extract all OU keys from ou_scp_policies (OUs with policies assigned)
  # 2. Extract all OU keys from organizational_units (OUs being created)
  # 3. Find any keys in policies that don't exist in units (invalid keys)
  # 4. Fail deployment if any invalid keys found (see validation resource below)
  #
  # Example Scenario:
  #   organizational_units = { nonprod = {...}, prod = {...} }
  #   ou_scp_policies = { nonprod = [...], staging = [...] }
  #   Result: invalid_ou_keys = ["staging"] → Deployment fails with clear error

  ou_keys_in_policies = keys(var.ou_scp_policies)      # OUs with policies assigned
  ou_keys_defined     = keys(var.organizational_units) # OUs being created
  invalid_ou_keys = setsubtract(                       # Keys in policies but not in units
    local.ou_keys_in_policies,
    local.ou_keys_defined
  )
}

# ============================================================================
# Validation Resource - OU Key Consistency
# ============================================================================
# Enforces that all OU keys in ou_scp_policies exist in organizational_units.
# This validation runs during the plan phase, catching configuration errors
# before any resources are created.
#
# Why This Matters:
# - Prevents runtime errors from missing OU references
# - Provides clear error messages for misconfiguration
# - Fails fast before expensive resource creation
# - Ensures data consistency across variables
#
# Error Message Example:
#   "The following OU keys in ou_scp_policies do not exist in 
#    organizational_units: staging, sandbox"
#
# When This Fails:
# - Typo in OU key name (e.g., "non-prod" vs "nonprod")
# - Policy assigned to OU that wasn't created
# - Copy-paste error from another environment
#
# How to Fix:
# 1. Check spelling of OU keys in both variables
# 2. Ensure OU is defined in organizational_units
# 3. Remove policy assignment if OU shouldn't exist

resource "null_resource" "validate_ou_keys" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_ou_keys) == 0
      error_message = "The following OU keys in ou_scp_policies do not exist in organizational_units: ${join(", ", local.invalid_ou_keys)}"
    }
  }
}
