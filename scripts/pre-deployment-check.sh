#!/bin/bash
set -e

# ============================================================================
# Pre-Deployment Validation Script for AWS Control Tower
# ============================================================================

echo "=========================================="
echo "Control Tower Pre-Deployment Validation"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
echo "Checking AWS CLI..."
if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗ AWS CLI is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AWS CLI is installed${NC}"

# Check if Terraform is installed
echo "Checking Terraform..."
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗ Terraform is not installed${NC}"
    exit 1
fi
TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
echo -e "${GREEN}✓ Terraform ${TERRAFORM_VERSION} is installed${NC}"

# Check AWS credentials
echo ""
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}✗ AWS credentials are not configured${NC}"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CALLER_ARN=$(aws sts get-caller-identity --query Arn --output text)
echo -e "${GREEN}✓ AWS credentials are valid${NC}"
echo "  Account ID: ${ACCOUNT_ID}"
echo "  Caller ARN: ${CALLER_ARN}"

# Check if Organizations is enabled
echo ""
echo "Checking AWS Organizations..."
if ! aws organizations describe-organization &> /dev/null; then
    echo -e "${RED}✗ AWS Organizations is not enabled${NC}"
    echo "  Please enable AWS Organizations before deploying Control Tower"
    exit 1
fi

ORG_ID=$(aws organizations describe-organization --query 'Organization.Id' --output text)
MASTER_ACCOUNT=$(aws organizations describe-organization --query 'Organization.MasterAccountId' --output text)
echo -e "${GREEN}✓ AWS Organizations is enabled${NC}"
echo "  Organization ID: ${ORG_ID}"
echo "  Master Account: ${MASTER_ACCOUNT}"

# Verify we're in the management account
echo ""
echo "Verifying management account..."
if [ "$ACCOUNT_ID" != "$MASTER_ACCOUNT" ]; then
    echo -e "${RED}✗ You must run this from the management account${NC}"
    echo "  Current Account: ${ACCOUNT_ID}"
    echo "  Management Account: ${MASTER_ACCOUNT}"
    exit 1
fi
echo -e "${GREEN}✓ Running from management account${NC}"

# Check for existing Control Tower
echo ""
echo "Checking for existing Control Tower..."
if aws controltower list-landing-zones &> /dev/null; then
    LANDING_ZONES=$(aws controltower list-landing-zones --query 'landingZones[*].arn' --output text)
    if [ -n "$LANDING_ZONES" ]; then
        echo -e "${YELLOW}⚠ Control Tower landing zone already exists${NC}"
        echo "  Landing Zones: ${LANDING_ZONES}"
        echo "  This deployment may update the existing landing zone"
    else
        echo -e "${GREEN}✓ No existing Control Tower landing zone found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Unable to check for existing Control Tower${NC}"
fi

# Check required service quotas
echo ""
echo "Checking service quotas..."
echo -e "${YELLOW}⚠ Please manually verify the following service quotas:${NC}"
echo "  - Organizations: Organizational Units (default: 1000)"
echo "  - Organizations: Accounts (default: 10, can be increased)"
echo "  - Organizations: SCPs (default: 1000)"
echo "  - Control Tower: Landing Zones per region (default: 1)"

# Check IAM permissions
echo ""
echo "Checking IAM permissions..."
echo -e "${YELLOW}⚠ Ensure your IAM user/role has the following permissions:${NC}"
echo "  - AWSControlTowerServiceRolePolicy"
echo "  - AWSOrganizationsFullAccess"
echo "  - IAMFullAccess"
echo "  - CloudFormationFullAccess"
echo "  - S3FullAccess (for state backend)"

# Validate Terraform configuration
echo ""
echo "Validating Terraform configuration..."
if terraform init -backend=false &> /dev/null; then
    echo -e "${GREEN}✓ Terraform initialization successful${NC}"
else
    echo -e "${RED}✗ Terraform initialization failed${NC}"
    exit 1
fi

if terraform validate &> /dev/null; then
    echo -e "${GREEN}✓ Terraform configuration is valid${NC}"
else
    echo -e "${RED}✗ Terraform configuration is invalid${NC}"
    terraform validate
    exit 1
fi

# Check for terraform.tfvars
echo ""
echo "Checking configuration files..."
if [ -f "terraform.tfvars" ]; then
    echo -e "${GREEN}✓ terraform.tfvars found${NC}"
elif [ -f "terraform.tfvars.production" ]; then
    echo -e "${YELLOW}⚠ terraform.tfvars not found, but terraform.tfvars.production exists${NC}"
    echo "  Consider copying it: cp terraform.tfvars.production terraform.tfvars"
else
    echo -e "${YELLOW}⚠ terraform.tfvars not found${NC}"
    echo "  Copy terraform.tfvars.example and customize it"
fi

# Summary
echo ""
echo "=========================================="
echo "Pre-Deployment Validation Complete"
echo "=========================================="
echo ""
echo -e "${GREEN}All automated checks passed!${NC}"
echo ""
echo "Next steps:"
echo "1. Review and customize terraform.tfvars"
echo "2. Configure remote state backend in versions.tf"
echo "3. Run: terraform plan"
echo "4. Review the plan carefully"
echo "5. Run: terraform apply"
echo ""
echo -e "${YELLOW}Note: Control Tower deployment can take 60-90 minutes${NC}"
