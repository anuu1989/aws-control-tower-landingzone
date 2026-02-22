#!/bin/bash
# ============================================================================
# Git Secrets Setup Script
# ============================================================================
# This script installs and configures git-secrets to prevent committing
# AWS credentials and other sensitive information to the repository.
#
# Usage:
#   ./scripts/setup-git-secrets.sh
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

# Check if git-secrets is installed
log_step "Checking if git-secrets is installed..."
if command -v git-secrets &> /dev/null; then
    log_info "git-secrets is already installed"
else
    log_warn "git-secrets is not installed"
    
    # Detect OS and provide installation instructions
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "Installing git-secrets via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install git-secrets
        else
            log_error "Homebrew is not installed. Please install Homebrew first:"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_info "Installing git-secrets from source..."
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"
        git clone https://github.com/awslabs/git-secrets.git
        cd git-secrets
        sudo make install
        cd -
        rm -rf "$TEMP_DIR"
    else
        log_error "Unsupported OS. Please install git-secrets manually:"
        echo "  https://github.com/awslabs/git-secrets"
        exit 1
    fi
fi

# Initialize git-secrets in the repository
log_step "Initializing git-secrets in the repository..."
if git secrets --install; then
    log_info "git-secrets initialized successfully"
else
    log_warn "git-secrets may already be initialized"
fi

# Register AWS patterns
log_step "Registering AWS secret patterns..."
git secrets --register-aws

# Add custom patterns for Terraform
log_step "Adding custom patterns for Terraform..."

# Terraform AWS provider credentials
git secrets --add 'access_key\s*=\s*"[A-Z0-9]{20}"'
git secrets --add 'secret_key\s*=\s*"[A-Za-z0-9/+=]{40}"'

# AWS credentials in various formats
git secrets --add 'AKIA[0-9A-Z]{16}'
git secrets --add 'aws_access_key_id\s*=\s*[A-Z0-9]{20}'
git secrets --add 'aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}'

# Private keys
git secrets --add '-----BEGIN RSA PRIVATE KEY-----'
git secrets --add '-----BEGIN OPENSSH PRIVATE KEY-----'
git secrets --add '-----BEGIN PRIVATE KEY-----'

# Generic secrets
git secrets --add 'password\s*=\s*["\'][^"\']{8,}["\']'
git secrets --add 'api_key\s*=\s*["\'][^"\']{20,}["\']'
git secrets --add 'token\s*=\s*["\'][^"\']{20,}["\']'

# Add allowed patterns (false positives)
log_step "Adding allowed patterns..."
git secrets --add --allowed 'example\.com'
git secrets --add --allowed 'EXAMPLE'
git secrets --add --allowed 'YOUR_'
git secrets --add --allowed 'REPLACE_'
git secrets --add --allowed '\[email\]'
git secrets --add --allowed '\[password\]'
git secrets --add --allowed 'aws-dev@example\.com'
git secrets --add --allowed 'aws-prod@example\.com'

# Scan existing repository
log_step "Scanning existing repository for secrets..."
if git secrets --scan; then
    log_info "No secrets found in repository"
else
    log_error "Secrets detected in repository! Please review and remove them."
    echo ""
    echo "To scan specific files:"
    echo "  git secrets --scan <file>"
    echo ""
    echo "To scan all history:"
    echo "  git secrets --scan-history"
    exit 1
fi

# Create git hooks
log_step "Setting up git hooks..."
cat > .git/hooks/commit-msg << 'EOF'
#!/bin/bash
# Git secrets commit-msg hook
git secrets --commit_msg_hook -- "$@"
EOF

cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Git secrets pre-commit hook
git secrets --pre_commit_hook -- "$@"
EOF

cat > .git/hooks/prepare-commit-msg << 'EOF'
#!/bin/bash
# Git secrets prepare-commit-msg hook
git secrets --prepare_commit_msg_hook -- "$@"
EOF

chmod +x .git/hooks/commit-msg
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/prepare-commit-msg

log_info "Git hooks created successfully"

# Print summary
echo ""
echo "============================================================================"
log_info "git-secrets setup completed successfully!"
echo "============================================================================"
echo ""
echo "What's configured:"
echo "  ✓ AWS credential patterns"
echo "  ✓ Private key patterns"
echo "  ✓ Generic secret patterns"
echo "  ✓ Git hooks (pre-commit, commit-msg, prepare-commit-msg)"
echo ""
echo "To scan all history:"
echo "  git secrets --scan-history"
echo ""
echo "To list all patterns:"
echo "  git secrets --list"
echo ""
echo "To add more patterns:"
echo "  git secrets --add '<pattern>'"
echo ""
echo "============================================================================"
