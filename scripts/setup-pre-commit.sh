#!/bin/bash
# ============================================================================
# Setup Pre-Commit Hooks
# ============================================================================
# This script installs and configures pre-commit hooks for the repository.
#
# Usage:
#   ./scripts/setup-pre-commit.sh
#
# Prerequisites:
#   - Python 3.7+
#   - pip
#
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setting up Pre-Commit Hooks${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 is not installed${NC}"
    echo -e "${YELLOW}Please install Python 3.7 or higher${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Python 3 found${NC}"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}✗ pip3 is not installed${NC}"
    echo -e "${YELLOW}Please install pip3${NC}"
    exit 1
fi

echo -e "${GREEN}✓ pip3 found${NC}"

# Install pre-commit
echo ""
echo -e "${BLUE}Installing pre-commit...${NC}"
pip3 install pre-commit --user

# Verify installation
if ! command -v pre-commit &> /dev/null; then
    echo -e "${YELLOW}⚠ pre-commit not found in PATH${NC}"
    echo -e "${YELLOW}You may need to add ~/.local/bin to your PATH${NC}"
    echo -e "${YELLOW}Add this to your ~/.bashrc or ~/.zshrc:${NC}"
    echo -e "${YELLOW}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    exit 1
fi

echo -e "${GREEN}✓ pre-commit installed${NC}"

# Install pre-commit hooks
echo ""
echo -e "${BLUE}Installing pre-commit hooks...${NC}"
pre-commit install

echo -e "${GREEN}✓ Pre-commit hooks installed${NC}"

# Install commit-msg hook
echo ""
echo -e "${BLUE}Installing commit-msg hook...${NC}"
pre-commit install --hook-type commit-msg

echo -e "${GREEN}✓ Commit-msg hook installed${NC}"

# Initialize detect-secrets baseline
echo ""
echo -e "${BLUE}Initializing detect-secrets baseline...${NC}"
if [ ! -f .secrets.baseline ]; then
    detect-secrets scan > .secrets.baseline
    echo -e "${GREEN}✓ Secrets baseline created${NC}"
else
    echo -e "${YELLOW}⚠ Secrets baseline already exists${NC}"
fi

# Run pre-commit on all files (optional)
echo ""
read -p "Run pre-commit on all files now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Running pre-commit on all files...${NC}"
    pre-commit run --all-files || true
    echo -e "${GREEN}✓ Pre-commit run complete${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Pre-commit setup complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Pre-commit hooks will run automatically on git commit"
echo -e "2. To run manually: ${YELLOW}pre-commit run --all-files${NC}"
echo -e "3. To skip hooks (emergency): ${YELLOW}git commit --no-verify${NC}"
echo -e "4. To update hooks: ${YELLOW}pre-commit autoupdate${NC}"
echo ""
echo -e "${BLUE}Installed hooks:${NC}"
echo -e "  - Terraform fmt, validate, docs"
echo -e "  - tfsec security scanning"
echo -e "  - TFLint linting"
echo -e "  - Checkov policy checking"
echo -e "  - Secret detection"
echo -e "  - YAML/JSON validation"
echo -e "  - Markdown linting"
echo -e "  - Shell script checking"
echo ""
