package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// ============================================================================
// Control Tower Deployment Tests
// ============================================================================

func TestControlTowerDeployment(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"environment":                    "test",
			"project_name":                   "ct-test",
			"home_region":                    "ap-southeast-2",
			"enable_centralized_networking":  false,
			"security_notification_emails":   []string{"test@example.com"},
			"operational_notification_emails": []string{"ops@example.com"},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and plan
	terraform.InitAndPlan(t, terraformOptions)
}

func TestControlTowerOutputs(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../",
		Vars: map[string]interface{}{
			"environment":                    "test",
			"project_name":                   "ct-test",
			"enable_centralized_networking":  false,
			"security_notification_emails":   []string{"test@example.com"},
			"operational_notification_emails": []string{"ops@example.com"},
		},
	}

	terraform.InitAndPlan(t, terraformOptions)
	
	// Verify expected outputs exist
	expectedOutputs := []string{
		"organization_id",
		"organization_arn",
		"root_id",
		"organizational_units",
		"scp_policies",
		"kms_key",
		"guardduty",
		"security_hub",
		"logging",
	}

	for _, output := range expectedOutputs {
		terraform.OutputRequired(t, terraformOptions, output)
	}
}

func TestVariableValidation(t *testing.T) {
	tests := []struct {
		name        string
		vars        map[string]interface{}
		expectError bool
	}{
		{
			name: "Valid configuration",
			vars: map[string]interface{}{
				"environment":  "production",
				"project_name": "test-project",
				"home_region":  "ap-southeast-2",
			},
			expectError: false,
		},
		{
			name: "Invalid environment",
			vars: map[string]interface{}{
				"environment":  "invalid",
				"project_name": "test-project",
				"home_region":  "ap-southeast-2",
			},
			expectError: true,
		},
		{
			name: "Invalid project name",
			vars: map[string]interface{}{
				"environment":  "production",
				"project_name": "Test_Project",
				"home_region":  "ap-southeast-2",
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: "../../",
				Vars:         tt.vars,
			}

			_, err := terraform.InitAndPlanE(t, terraformOptions)
			
			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}
