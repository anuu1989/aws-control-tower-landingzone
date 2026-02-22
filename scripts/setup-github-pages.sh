#!/bin/bash
# ============================================================================
# GitHub Pages Setup Script
# ============================================================================
# This script helps set up the GitHub Pages documentation site.
#
# Usage:
#   ./scripts/setup-github-pages.sh
#
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running from project root
if [ ! -f "README.md" ] || [ ! -d "docs" ]; then
    log_error "This script must be run from the project root directory"
    exit 1
fi

log_info "Setting up GitHub Pages documentation site..."
echo ""

# Step 1: Check Ruby installation
log_step "Checking Ruby installation..."
if command -v ruby &> /dev/null; then
    RUBY_VERSION=$(ruby --version | awk '{print $2}')
    log_info "Ruby $RUBY_VERSION is installed"
else
    log_error "Ruby is not installed"
    echo ""
    echo "Please install Ruby:"
    echo "  macOS:   brew install ruby"
    echo "  Ubuntu:  sudo apt-get install ruby-full"
    echo "  Windows: https://rubyinstaller.org/"
    exit 1
fi

# Step 2: Check Bundler installation
log_step "Checking Bundler installation..."
if command -v bundle &> /dev/null; then
    log_info "Bundler is installed"
else
    log_warn "Bundler is not installed. Installing..."
    gem install bundler
fi

# Step 3: Install dependencies
log_step "Installing Jekyll and dependencies..."
cd docs
if bundle install; then
    log_info "Dependencies installed successfully"
else
    log_error "Failed to install dependencies"
    exit 1
fi
cd ..

# Step 4: Update GitHub repository URL
log_step "Configuring GitHub repository URL..."
echo ""
read -p "Enter your GitHub organization/username: " GITHUB_ORG
read -p "Enter your repository name: " GITHUB_REPO

if [ -n "$GITHUB_ORG" ] && [ -n "$GITHUB_REPO" ]; then
    # Update _config.yml
    sed -i.bak "s|your-org/aws-control-tower-landingzone|$GITHUB_ORG/$GITHUB_REPO|g" docs/_config.yml
    rm -f docs/_config.yml.bak
    log_info "Updated repository URL to: $GITHUB_ORG/$GITHUB_REPO"
else
    log_warn "Skipping repository URL configuration"
fi

# Step 5: Enable GitHub Pages
log_step "Enabling GitHub Pages..."
echo ""
log_info "To enable GitHub Pages:"
echo "  1. Go to: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/pages"
echo "  2. Under 'Build and deployment':"
echo "     - Source: GitHub Actions"
echo "  3. Save changes"
echo ""
read -p "Press Enter when you've enabled GitHub Pages..."

# Step 6: Test local build
log_step "Testing local build..."
cd docs
if bundle exec jekyll build; then
    log_info "Site built successfully!"
    log_info "Output in: docs/_site/"
else
    log_error "Build failed. Check errors above."
    exit 1
fi
cd ..

# Step 7: Start local server (optional)
echo ""
read -p "Would you like to start the local development server? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Starting Jekyll server..."
    log_info "Site will be available at: http://localhost:4000"
    log_info "Press Ctrl+C to stop the server"
    echo ""
    cd docs
    bundle exec jekyll serve --livereload
fi

# Summary
echo ""
echo "============================================================================"
log_info "GitHub Pages setup completed successfully!"
echo "============================================================================"
echo ""
echo "Next steps:"
echo "  1. Review the documentation in docs/"
echo "  2. Customize docs/_config.yml with your settings"
echo "  3. Add your logo to docs/assets/images/logo.png"
echo "  4. Commit and push changes to trigger deployment"
echo "  5. Access your site at: https://$GITHUB_ORG.github.io/$GITHUB_REPO/"
echo ""
echo "Local development:"
echo "  cd docs"
echo "  bundle exec jekyll serve --livereload"
echo "  Open: http://localhost:4000"
echo ""
echo "Documentation:"
echo "  See: docs/README_DOCS.md"
echo ""
echo "============================================================================"
