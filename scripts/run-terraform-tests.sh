#!/bin/bash
set -e

# ============================================================================
# Terraform Testing Script using Terratest
# ============================================================================

echo "=========================================="
echo "Running Terraform Tests"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Go is not installed${NC}"
    echo "Install Go: https://golang.org/doc/install"
    exit 1
fi

echo -e "${GREEN}✓ Go is installed${NC}"
GO_VERSION=$(go version)
echo "  Version: ${GO_VERSION}"
echo ""

# Navigate to test directory
cd tests/terraform

# Download dependencies
echo "Downloading Go dependencies..."
go mod download
go mod tidy

echo ""
echo "Running Terratest unit tests..."
echo ""

# Run tests with verbose output
if go test -v -timeout 30m; then
    echo ""
    echo -e "${GREEN}✓ All Terraform tests passed${NC}"
else
    echo ""
    echo -e "${RED}✗ Some Terraform tests failed${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo "Terraform Testing Complete"
echo "=========================================="
