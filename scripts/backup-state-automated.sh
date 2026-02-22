#!/bin/bash
# ============================================================================
# Automated Terraform State Backup Script
# ============================================================================
# This script creates automated backups of Terraform state files to S3
# with timestamped versions for disaster recovery purposes.
#
# Usage:
#   ./scripts/backup-state-automated.sh [backup-bucket-name]
#
# Schedule with cron:
#   0 */6 * * * /path/to/backup-state-automated.sh backup-bucket-name
#
# ============================================================================

set -euo pipefail

# Configuration
BACKUP_BUCKET="${1:-}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PREFIX="state-backups"
RETENTION_DAYS=90

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Validate inputs
if [ -z "$BACKUP_BUCKET" ]; then
    log_error "Backup bucket name is required"
    echo "Usage: $0 <backup-bucket-name>"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    log_error "Terraform is not installed"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed"
    exit 1
fi

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    log_error "Terraform is not initialized. Run 'terraform init' first."
    exit 1
fi

log_info "Starting Terraform state backup..."

# Pull current state
log_info "Pulling current Terraform state..."
STATE_FILE="terraform.tfstate.$DATE"
if terraform state pull > "$STATE_FILE"; then
    log_info "State pulled successfully"
else
    log_error "Failed to pull Terraform state"
    exit 1
fi

# Verify state file is not empty
if [ ! -s "$STATE_FILE" ]; then
    log_error "State file is empty"
    rm -f "$STATE_FILE"
    exit 1
fi

# Upload to S3
log_info "Uploading state backup to S3..."
S3_PATH="s3://${BACKUP_BUCKET}/${BACKUP_PREFIX}/${STATE_FILE}"
if aws s3 cp "$STATE_FILE" "$S3_PATH" --server-side-encryption AES256; then
    log_info "State backup uploaded to $S3_PATH"
else
    log_error "Failed to upload state backup to S3"
    rm -f "$STATE_FILE"
    exit 1
fi

# Clean up local file
rm -f "$STATE_FILE"
log_info "Local state file cleaned up"

# Clean up old backups (older than retention period)
log_info "Cleaning up backups older than $RETENTION_DAYS days..."
CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" +%Y%m%d 2>/dev/null || date -v-${RETENTION_DAYS}d +%Y%m%d)

aws s3 ls "s3://${BACKUP_BUCKET}/${BACKUP_PREFIX}/" | while read -r line; do
    FILE_DATE=$(echo "$line" | awk '{print $4}' | grep -oE '[0-9]{8}' | head -1)
    FILE_NAME=$(echo "$line" | awk '{print $4}')
    
    if [ -n "$FILE_DATE" ] && [ "$FILE_DATE" -lt "$CUTOFF_DATE" ]; then
        log_info "Deleting old backup: $FILE_NAME"
        aws s3 rm "s3://${BACKUP_BUCKET}/${BACKUP_PREFIX}/${FILE_NAME}"
    fi
done

# List recent backups
log_info "Recent backups:"
aws s3 ls "s3://${BACKUP_BUCKET}/${BACKUP_PREFIX}/" --recursive | tail -5

log_info "State backup completed successfully!"
