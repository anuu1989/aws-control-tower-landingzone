#!/bin/bash
set -e

# ============================================================================
# Complete Validation Script
# ============================================================================

echo "=========================================="
echo "Control Tower Complete Validation"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED=0

# ============================================================================
# 1. Terraform Format Check
# ============================================================================

echo -e "${BLUE}[1/7] Checking Terraform formatting...${NC}"
if terraform fmt -check -recursive; then
    echo -e "${GREEN}✓ Terraform formatting is correct${NC}"
else
    echo -e "${RED}✗ Terraform formatting issues found${NC}"
    echo "Run: terraform fmt -recursive"
    FAILED=1
fi
echo ""

# ============================================================================
# 2. Terraform Validation
# ============================================================================

echo -e "${BLUE}[2/7] Validating Terraform configuration...${NC}"
terraform init -backend=false > /dev/null 2>&1
if terraform validate; then
    echo -e "${GREEN}✓ Terraform configuration is valid${NC}"
else
    echo -e "${RED}✗ Terraform validation failed${NC}"
    FAILED=1
fi
echo ""

# ============================================================================
# 3. TFLint
# ============================================================================

echo -e "${BLUE}[3/7] Running TFLint...${NC}"
if command -v tflint &> /dev/null; then
    if tflint --init && tflint; then
        echo -e "${GREEN}✓ TFLint checks passed${NC}"
    else
        echo -e "${YELLOW}⚠ TFLint found issues${NC}"
    fi
else
    echo -e "${YELLOW}⚠ TFLint not installed (optional)${NC}"
fi
echo ""

# ============================================================================
# 4. TFSec Security Scan
# ============================================================================

echo -e "${BLUE}[4/7] Running TFSec security scan...${NC}"
if command -v tfsec &> /dev/null; then
    if tfsec . --soft-fail; then
        echo -e "${GREEN}✓ TFSec security scan passed${NC}"
    else
        echo -e "${YELLOW}⚠ TFSec found security issues${NC}"
    fi
else
    echo -e "${YELLOW}⚠ TFSec not installed (optional)${NC}"
    echo "Install: brew install tfsec"
fi
echo ""

# ============================================================================
# 5. Checkov Security Scan
# ============================================================================

echo -e "${BLUE}[5/7] Running Checkov security scan...${NC}"
if command -v checkov &> /dev/null; then
    if checkov -d . --quiet --compact --soft-fail; then
        echo -e "${GREEN}✓ Checkov security scan passed${NC}"
    else
        echo -e "${YELLOW}⚠ Checkov found security issues${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Checkov not installed (optional)${NC}"
    echo "Install: pip install checkov"
fi
echo ""

# ============================================================================
# 6. OPA Policy Tests
# ============================================================================

echo -e "${BLUE}[6/7] Running OPA policy tests...${NC}"
if command -v opa &> /dev/null; then
    if bash scripts/run-opa-tests.sh; then
        echo -e "${GREEN}✓ OPA policy tests passed${NC}"
    else
        echo -e "${RED}✗ OPA policy tests failed${NC}"
        FAILED=1
    fi
else
    echo -e "${YELLOW}⚠ OPA not installed${NC}"
    echo "Install: https://www.openpolicyagent.org/docs/latest/#running-opa"
fi
echo ""

# ============================================================================
# 7. Terraform Plan
# ============================================================================

echo -e "${BLUE}[7/7] Generating Terraform plan...${NC}"
if [ -f "terraform.tfvars" ]; then
    if terraform plan -out=tfplan > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Terraform plan generated successfully${NC}"
        
        # Convert plan to JSON for OPA validation
        terraform show -json tfplan > tfplan.json
        echo -e "${GREEN}✓ Plan exported to JSON${NC}"
    else
        echo -e "${RED}✗ Terraform plan failed${NC}"
        FAILED=1
    fi
else
    echo -e "${YELLOW}⚠ terraform.tfvars not found${NC}"
    echo "Copy terraform.tfvars.production to terraform.tfvars and customize"
fi
echo ""

# ============================================================================
# Summary
# ============================================================================

echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All validations passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review the Terraform plan: terraform show tfplan"
    echo "2. Apply the configuration: terraform apply tfplan"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some validations failed${NC}"
    echo ""
    echo "Please fix the issues above before deploying."
    echo ""
    exit 1
fi
