#!/bin/bash
set -e

# ============================================================================
# OPA Policy Testing Script
# ============================================================================

echo "=========================================="
echo "Running OPA Policy Tests"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if OPA is installed
if ! command -v opa &> /dev/null; then
    echo -e "${RED}✗ OPA is not installed${NC}"
    echo "Install OPA: https://www.openpolicyagent.org/docs/latest/#running-opa"
    exit 1
fi

echo -e "${GREEN}✓ OPA is installed${NC}"
OPA_VERSION=$(opa version | head -n 1)
echo "  Version: ${OPA_VERSION}"
echo ""

# Run OPA tests
echo "Running OPA unit tests..."
if opa test policies/opa/ -v; then
    echo -e "${GREEN}✓ All OPA tests passed${NC}"
else
    echo -e "${RED}✗ Some OPA tests failed${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo "OPA Policy Validation"
echo "=========================================="
echo ""

# Validate Terraform plan against OPA policies
if [ -f "tfplan.json" ]; then
    echo "Validating Terraform plan against OPA policies..."
    
    # Run OPA evaluation
    opa eval \
        --data policies/opa/terraform.rego \
        --input tfplan.json \
        --format pretty \
        'data.terraform.controltower.deny'
    
    # Check for violations
    VIOLATIONS=$(opa eval \
        --data policies/opa/terraform.rego \
        --input tfplan.json \
        --format raw \
        'data.terraform.controltower.violation_count' | jq -r '.[0].result')
    
    WARNINGS=$(opa eval \
        --data policies/opa/terraform.rego \
        --input tfplan.json \
        --format raw \
        'data.terraform.controltower.warning_count' | jq -r '.[0].result')
    
    echo ""
    echo "Policy Validation Results:"
    echo "  Violations: ${VIOLATIONS}"
    echo "  Warnings: ${WARNINGS}"
    
    if [ "$VIOLATIONS" -gt 0 ]; then
        echo -e "${RED}✗ Policy violations found${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ No policy violations${NC}"
    fi
    
    if [ "$WARNINGS" -gt 0 ]; then
        echo -e "${YELLOW}⚠ Warnings found (non-blocking)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No tfplan.json found. Run 'terraform plan -out=tfplan && terraform show -json tfplan > tfplan.json' first${NC}"
fi

echo ""
echo "=========================================="
echo "OPA Testing Complete"
echo "=========================================="
