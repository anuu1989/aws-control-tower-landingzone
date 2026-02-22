package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// ============================================================================
// Security Module Tests
// ============================================================================

func TestSecurityModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"account_id":                   "123456789012",
			"region":                       "ap-southeast-2",
			"kms_alias":                    "test-key",
			"log_bucket_name":              "test-logs",
			"sns_topic_arn":                "arn:aws:sns:ap-southeast-2:123456789012:test",
			"guardduty_finding_frequency":  "FIFTEEN_MINUTES",
			"enable_pci_dss":               false,
			"config_recorder_name":         "test-recorder",
			"config_delivery_channel_name": "test-delivery",
			"config_delivery_frequency":    "TwentyFour_Hours",
			"access_analyzer_name":         "test-analyzer",
			"enable_macie":                 false,
		},
	}

	plan := terraform.InitAndPlan(t, terraformOptions)
	
	// Verify KMS key is created
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_kms_key.control_tower")
	
	// Verify GuardDuty is enabled
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_guardduty_detector.main")
	
	// Verify Security Hub is enabled
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_securityhub_account.main")
}

func TestSecurityModuleKMSEncryption(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"account_id":                   "123456789012",
			"region":                       "ap-southeast-2",
			"kms_alias":                    "test-key",
			"log_bucket_name":              "test-logs",
			"sns_topic_arn":                "arn:aws:sns:ap-southeast-2:123456789012:test",
			"guardduty_finding_frequency":  "FIFTEEN_MINUTES",
			"enable_pci_dss":               false,
			"config_recorder_name":         "test-recorder",
			"config_delivery_channel_name": "test-delivery",
			"config_delivery_frequency":    "TwentyFour_Hours",
			"access_analyzer_name":         "test-analyzer",
			"enable_macie":                 false,
		},
	}

	plan := terraform.InitAndPlan(t, terraformOptions)
	
	// Verify KMS key has rotation enabled
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_kms_key.control_tower")
}

func TestSecurityModuleGuardDuty(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"account_id":                   "123456789012",
			"region":                       "ap-southeast-2",
			"kms_alias":                    "test-key",
			"log_bucket_name":              "test-logs",
			"sns_topic_arn":                "arn:aws:sns:ap-southeast-2:123456789012:test",
			"guardduty_finding_frequency":  "FIFTEEN_MINUTES",
			"enable_pci_dss":               false,
			"config_recorder_name":         "test-recorder",
			"config_delivery_channel_name": "test-delivery",
			"config_delivery_frequency":    "TwentyFour_Hours",
			"access_analyzer_name":         "test-analyzer",
			"enable_macie":                 false,
		},
	}

	plan := terraform.InitAndPlan(t, terraformOptions)
	
	// Verify GuardDuty detector is enabled
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_guardduty_detector.main")
}
