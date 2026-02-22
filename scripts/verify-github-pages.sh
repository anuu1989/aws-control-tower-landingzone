#!/bin/bash
# ============================================================================
# GitHub Pages Verification Script
# ============================================================================
# This script verifies the GitHub Pages configuration is correct.
# ============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}GitHub Pages Configuration Verification${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""

ERRORS=0
WARNINGS=0

# Check if in correct directory
if [ ! -f "README.md" ] || [ ! -d "docs" ]; then
    echo -e "${RED}✗ Error: Must run from project root${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Running from project root${NC}"

# Check _config.yml exists
if [ ! -f "docs/_config.yml" ]; then
    echo -e "${RED}✗ Error: docs/_config.yml not found${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✓ docs/_config.yml exists${NC}"
    
    # Check for repository field
    if grep -q "^repository:" docs/_config.yml; then
        REPO=$(grep "^repository:" docs/_config.yml | cut -d: -f2 | tr -d ' ')
        echo -e "${GREEN}✓ Repository configured: $REPO${NC}"
    else
        echo -e "${RED}✗ Error: 'repository' field missing in _config.yml${NC}"
        ((ERRORS++))
    fi
    
    # Check for remote_theme
    if grep -q "^remote_theme:" docs/_config.yml; then
        THEME=$(grep "^remote_theme:" docs/_config.yml | cut -d: -f2 | tr -d ' ')
        echo -e "${GREEN}✓ Remote theme configured: $THEME${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Using local theme instead of remote_theme${NC}"
        ((WARNINGS++))
    fi
    
    # Check for baseurl
    if grep -q "^baseurl:" docs/_config.yml; then
        BASEURL=$(grep "^baseurl:" docs/_config.yml | cut -d: -f2 | tr -d ' "')
        echo -e "${GREEN}✓ Baseurl configured: $BASEURL${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: baseurl not configured${NC}"
        ((WARNINGS++))
    fi
fi

# Check Gemfile
if [ ! -f "docs/Gemfile" ]; then
    echo -e "${RED}✗ Error: docs/Gemfile not found${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✓ docs/Gemfile exists${NC}"
    
    # Check for github-pages gem
    if grep -q "github-pages" docs/Gemfile; then
        echo -e "${GREEN}✓ github-pages gem configured${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: github-pages gem not found${NC}"
        ((WARNINGS++))
    fi
    
    # Check for jekyll-remote-theme
    if grep -q "jekyll-remote-theme" docs/Gemfile; then
        echo -e "${GREEN}✓ jekyll-remote-theme plugin configured${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: jekyll-remote-theme plugin not found${NC}"
        ((WARNINGS++))
    fi
fi

# Check for custom layouts (should not exist)
if [ -d "docs/_layouts" ]; then
    echo -e "${YELLOW}⚠ Warning: Custom _layouts directory exists${NC}"
    echo -e "${YELLOW}  This may cause build errors. Consider removing it.${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ No custom layouts (good)${NC}"
fi

# Check GitHub Actions workflow
if [ ! -f ".github/workflows/github-pages.yml" ]; then
    echo -e "${RED}✗ Error: GitHub Actions workflow not found${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✓ GitHub Actions workflow exists${NC}"
    
    # Check for PAGES_REPO_NWO
    if grep -q "PAGES_REPO_NWO" .github/workflows/github-pages.yml; then
        echo -e "${GREEN}✓ PAGES_REPO_NWO environment variable configured${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: PAGES_REPO_NWO not set in workflow${NC}"
        ((WARNINGS++))
    fi
fi

# Check for index.md
if [ ! -f "docs/index.md" ]; then
    echo -e "${RED}✗ Error: docs/index.md not found${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✓ docs/index.md exists${NC}"
    
    # Check for front matter
    if head -n 1 docs/index.md | grep -q "^---$"; then
        echo -e "${GREEN}✓ index.md has front matter${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: index.md missing front matter${NC}"
        ((WARNINGS++))
    fi
fi

# Check Ruby installation
if command -v ruby &> /dev/null; then
    RUBY_VERSION=$(ruby --version | awk '{print $2}')
    echo -e "${GREEN}✓ Ruby installed: $RUBY_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Ruby not installed (needed for local testing)${NC}"
    ((WARNINGS++))
fi

# Check Bundler installation
if command -v bundle &> /dev/null; then
    BUNDLE_VERSION=$(bundle --version | awk '{print $3}')
    echo -e "${GREEN}✓ Bundler installed: $BUNDLE_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Bundler not installed (needed for local testing)${NC}"
    ((WARNINGS++))
fi

# Summary
echo ""
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}Verification Summary${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo -e "${GREEN}✓ Configuration is ready for deployment${NC}"
    EXIT_CODE=0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo -e "${YELLOW}  Configuration should work but may need attention${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}✗ $ERRORS error(s) found${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    fi
    echo -e "${RED}  Please fix errors before deploying${NC}"
    EXIT_CODE=1
fi

echo ""
echo "Next steps:"
echo "  1. Fix any errors or warnings above"
echo "  2. Test locally: cd docs && bundle exec jekyll serve"
echo "  3. Commit and push: git add . && git commit -m 'Fix config' && git push"
echo "  4. Monitor deployment: gh run watch"
echo ""

exit $EXIT_CODE
