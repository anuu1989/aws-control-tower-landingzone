package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// ============================================================================
// Networking Module Tests
// ============================================================================

func TestNetworkingModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"name_prefix":         "test",
			"inspection_vpc_cidr": "10.0.0.0/16",
			"availability_zones": []string{
				"ap-southeast-2a",
				"ap-southeast-2b",
				"ap-southeast-2c",
			},
			"log_bucket_name": "test-logs",
			"kms_key_id":      "arn:aws:kms:ap-southeast-2:123456789012:key/test",
			"sns_topic_arn":   "arn:aws:sns:ap-southeast-2:123456789012:test",
		},
	}

	plan := terraform.InitAndPlan(t, terraformOptions)
	
	// Verify Transit Gateway is created
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_ec2_transit_gateway.main")
	
	// Verify Network Firewall is created
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_networkfirewall_firewall.main")
	
	// Verify NAT Gateways are created
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_nat_gateway.inspection")
}

func TestNetworkingModuleTransitGateway(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"name_prefix":         "test",
			"inspection_vpc_cidr": "10.0.0.0/16",
			"availability_zones": []string{
				"ap-southeast-2a",
				"ap-southeast-2b",
				"ap-southeast-2c",
			},
			"log_bucket_name": "test-logs",
			"kms_key_id":      "arn:aws:kms:ap-southeast-2:123456789012:key/test",
			"sns_topic_arn":   "arn:aws:sns:ap-southeast-2:123456789012:test",
		},
	}

	plan := terraform.InitAndPlan(t, terraformOptions)
	
	// Verify Transit Gateway route tables
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_ec2_transit_gateway_route_table.shared")
}

func TestNetworkingModuleFirewall(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/networking",
		Vars: map[string]interface{}{
			"name_prefix":         "test",
			"inspection_vpc_cidr": "10.0.0.0/16",
			"availability_zones": []string{
				"ap-southeast-2a",
				"ap-southeast-2b",
				"ap-southeast-2c",
			},
			"log_bucket_name": "test-logs",
			"kms_key_id":      "arn:aws:kms:ap-southeast-2:123456789012:key/test",
			"sns_topic_arn":   "arn:aws:sns:ap-southeast-2:123456789012:test",
		},
	}

	plan := terraform.InitAndPlan(t, terraformOptions)
	
	// Verify Network Firewall policy
	terraform.RequirePlannedValuesMapKeyExists(t, plan, "aws_networkfirewall_firewall_policy.main")
}
