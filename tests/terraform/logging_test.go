package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// ============================================================================
// Logging Module Tests
// ============================================================================

func TestLoggingModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/logging",
		Vars: map[string]interface{}{
			"log_bucket_name":     "test-logs-bucket",
			"cloudtrail_name":     "test-trail",
			"kms_key_id":          "arn:aws:kms:ap-southeast-2:123456789012:key/test",
			"sns_topic_arn":       "arn:aws:sns:ap-southeast-2:123456789012:test",
			"log_retention_days":  2555,
			"log_transition_days": 90,
		},
	}

	plan := terraform.InitAndPlan(t, terraformOptions)
	
	// Verify S3 bucket is created
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_s3_bucket.log_archive")
	
	// Verify CloudTrail is created
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_cloudtrail.organization")
	
	// Verify encryption is enabled
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_s3_bucket_server_side_encryption_configuration.log_archive")
}

func TestLoggingModuleCloudTrail(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/logging",
		Vars: map[string]interface{}{
			"log_bucket_name":     "test-logs-bucket",
			"cloudtrail_name":     "test-trail",
			"kms_key_id":          "arn:aws:kms:ap-southeast-2:123456789012:key/test",
			"sns_topic_arn":       "arn:aws:sns:ap-southeast-2:123456789012:test",
			"log_retention_days":  2555,
			"log_transition_days": 90,
		},
	}

	plan := terraform.InitAndPlan(t, terraformOptions)
	
	// Verify CloudTrail configuration
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_cloudtrail.organization")
}

func TestLoggingModuleS3Lifecycle(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/logging",
		Vars: map[string]interface{}{
			"log_bucket_name":     "test-logs-bucket",
			"cloudtrail_name":     "test-trail",
			"kms_key_id":          "arn:aws:kms:ap-southeast-2:123456789012:key/test",
			"sns_topic_arn":       "arn:aws:sns:ap-southeast-2:123456789012:test",
			"log_retention_days":  2555,
			"log_transition_days": 90,
		},
	}

	plan := terraform.InitAndPlan(t, terraformOptions)
	
	// Verify lifecycle configuration
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_s3_bucket_lifecycle_configuration.log_archive")
}
