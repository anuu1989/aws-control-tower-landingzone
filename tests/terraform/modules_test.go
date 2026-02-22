package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// ============================================================================
// Module Tests - Organizational Units
// ============================================================================

func TestOrganizationalUnitsModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/organizational-units",
		Vars: map[string]interface{}{
			"parent_id": "r-test123",
			"organizational_units": map[string]interface{}{
				"nonprod": map[string]interface{}{
					"name":        "NonProd",
					"environment": "non-prod",
					"tags":        map[string]string{},
				},
				"prod": map[string]interface{}{
					"name":        "Prod",
					"environment": "prod",
					"tags":        map[string]string{},
				},
			},
		},
	}

	terraform.InitAndPlan(t, terraformOptions)
}

// ============================================================================
// Module Tests - SCP Policies
// ============================================================================

func TestSCPPoliciesModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/scp-policies",
		Vars: map[string]interface{}{
			"enabled_policies": []string{
				"deny_root_user",
				"require_mfa",
				"restrict_regions",
			},
			"allowed_regions": []string{
				"ap-southeast-2",
				"us-east-1",
			},
			"allowed_instance_types": []string{
				"t3.*",
				"t3a.*",
			},
		},
	}

	plan := terraform.InitAndPlan(t, terraformOptions)
	
	// Verify that policies are created
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_organizations_policy.scp")
}

// ============================================================================
// Module Tests - SCP Attachments
// ============================================================================

func TestSCPAttachmentsModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/scp-attachments",
		Vars: map[string]interface{}{
			"ou_policy_attachments": map[string]interface{}{
				"ou-test-123": []string{"policy-1", "policy-2"},
			},
		},
	}

	terraform.InitAndPlan(t, terraformOptions)
}
