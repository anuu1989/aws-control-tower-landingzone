#!/bin/bash
set -e

# ============================================================================
# Terraform Backend Setup Script
# ============================================================================
# This script deploys the Terraform backend infrastructure
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Terraform Backend Setup"
echo "=========================================="
echo ""

# ============================================================================
# Check Prerequisites
# ============================================================================

echo -e "${BLUE}[1/6] Checking prerequisites...${NC}"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗ AWS CLI not found${NC}"
    echo "Install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi
echo -e "${GREEN}✓ AWS CLI installed${NC}"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗ Terraform not found${NC}"
    echo "Install Terraform: https://www.terraform.io/downloads"
    exit 1
fi
echo -e "${GREEN}✓ Terraform installed${NC}"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}✗ AWS credentials not configured${NC}"
    echo "Configure AWS CLI: aws configure"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials configured${NC}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "  Account ID: ${ACCOUNT_ID}"

echo ""

# ============================================================================
# Check Configuration
# ============================================================================

echo -e "${BLUE}[2/6] Checking configuration...${NC}"

cd backend

if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}⚠ terraform.tfvars not found${NC}"
    echo "Creating from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${YELLOW}⚠ Please edit backend/terraform.tfvars with your values${NC}"
    echo ""
    echo "Required changes:"
    echo "  1. Set unique state_bucket_name"
    echo "  2. Add your AWS account ID to allowed_account_ids"
    echo "  3. Review and adjust other settings"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Configuration file found${NC}"
echo ""

# ============================================================================
# Initialize Terraform
# ============================================================================

echo -e "${BLUE}[3/6] Initializing Terraform...${NC}"

if terraform init; then
    echo -e "${GREEN}✓ Terraform initialized${NC}"
else
    echo -e "${RED}✗ Terraform initialization failed${NC}"
    exit 1
fi

echo ""

# ============================================================================
# Validate Configuration
# ============================================================================

echo -e "${BLUE}[4/6] Validating configuration...${NC}"

if terraform validate; then
    echo -e "${GREEN}✓ Configuration valid${NC}"
else
    echo -e "${RED}✗ Configuration validation failed${NC}"
    exit 1
fi

echo ""

# ============================================================================
# Plan Deployment
# ============================================================================

echo -e "${BLUE}[5/6] Planning deployment...${NC}"

if terraform plan -out=tfplan; then
    echo -e "${GREEN}✓ Plan generated${NC}"
else
    echo -e "${RED}✗ Planning failed${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo "Review the plan above"
echo "=========================================="
echo ""
echo "Resources to be created:"
echo "  • S3 bucket for state storage"
echo "  • S3 bucket for access logs"
echo "  • DynamoDB table for state locking"
echo "  • KMS key for encryption"
echo "  • IAM policy for backend access"
echo "  • CloudWatch alarms"
echo "  • EventBridge rules"
echo ""

read -p "Do you want to proceed with deployment? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# ============================================================================
# Deploy Backend
# ============================================================================

echo -e "${BLUE}[6/6] Deploying backend infrastructure...${NC}"

if terraform apply tfplan; then
    echo -e "${GREEN}✓ Backend deployed successfully${NC}"
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi

echo ""

# ============================================================================
# Save Configuration
# ============================================================================

echo "=========================================="
echo "Saving backend configuration..."
echo "=========================================="
echo ""

# Save backend config to JSON
terraform output -json backend_config > ../backend-config.json
echo -e "${GREEN}✓ Saved to backend-config.json${NC}"

# Extract values for backend.hcl
BUCKET=$(terraform output -raw state_bucket_name)
REGION=$(terraform output -raw kms_key_arn | cut -d: -f4)
KMS_KEY=$(terraform output -raw kms_key_arn)
DYNAMODB_TABLE=$(terraform output -raw lock_table_name)

# Create backend.hcl
cat > ../backend.hcl <<EOF
# Terraform Backend Configuration
# Generated by setup-backend.sh

bucket         = "${BUCKET}"
key            = "control-tower/terraform.tfstate"
region         = "${REGION}"
encrypt        = true
kms_key_id     = "${KMS_KEY}"
dynamodb_table = "${DYNAMODB_TABLE}"
EOF

echo -e "${GREEN}✓ Created backend.hcl${NC}"

cd ..

echo ""
echo "=========================================="
echo "Backend Setup Complete!"
echo "=========================================="
echo ""
echo "Backend Configuration:"
echo "  Bucket:         ${BUCKET}"
echo "  Region:         ${REGION}"
echo "  DynamoDB Table: ${DYNAMODB_TABLE}"
echo ""
echo "Next Steps:"
echo ""
echo "1. Initialize main Terraform with backend:"
echo "   ${GREEN}terraform init -backend-config=backend.hcl${NC}"
echo ""
echo "2. Verify backend configuration:"
echo "   ${GREEN}terraform state list${NC}"
echo ""
echo "3. Deploy Control Tower infrastructure:"
echo "   ${GREEN}terraform plan${NC}"
echo "   ${GREEN}terraform apply${NC}"
echo ""
echo "Backend configuration saved to:"
echo "  • backend.hcl (for terraform init)"
echo "  • backend-config.json (for reference)"
echo ""
