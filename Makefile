# ============================================================================
# Makefile for AWS Control Tower Terraform Deployment
# ============================================================================
# This Makefile provides convenient commands for managing the Control Tower
# deployment lifecycle, including validation, testing, deployment, and
# operational tasks.
#
# Prerequisites:
# - Terraform >= 1.6.0
# - AWS CLI >= 2.0
# - Go >= 1.21 (for unit tests)
# - OPA (for policy tests)
# - tfsec (for security scanning)
# - TFLint (for linting)
#
# Usage:
#   make help          - Show available commands
#   make check-prereqs - Verify prerequisites
#   make init          - Initialize Terraform
#   make plan          - Generate Terraform plan
#   make apply         - Apply Terraform changes
#   make test-all      - Run all tests
#
# Environment Variables:
#   ENVIRONMENT - Target environment (default: production)
#   TF_VAR_*    - Terraform variables
#
# ============================================================================

.PHONY: help init validate plan apply destroy clean check-prereqs format docs

# Default target
.DEFAULT_GOAL := help

# ============================================================================
# Variables
# ============================================================================
TERRAFORM := terraform
AWS := aws
OPA := opa
TFSEC := tfsec
TFLINT := tflint
GO := go
ENVIRONMENT ?= production
TFVARS_FILE := terraform.tfvars.$(ENVIRONMENT)

# Colors for output
COLOR_RESET := \033[0m
COLOR_BLUE := \033[36m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_RED := \033[31m

# ============================================================================
# Help Target
# ============================================================================
help: ## Show this help message
	@echo '$(COLOR_BLUE)AWS Control Tower Terraform Makefile$(COLOR_RESET)'
	@echo ''
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_BLUE)%-25s$(COLOR_RESET) %s\n", $$1, $$2}'
	@echo ''
	@echo 'Environment: $(COLOR_GREEN)$(ENVIRONMENT)$(COLOR_RESET)'
	@echo 'Terraform vars file: $(COLOR_GREEN)$(TFVARS_FILE)$(COLOR_RESET)'

# ============================================================================
# Prerequisites and Setup
# ============================================================================
check-prereqs: ## Check prerequisites (AWS CLI, Terraform, credentials)
	@echo "$(COLOR_BLUE)Checking prerequisites...$(COLOR_RESET)"
	@command -v $(AWS) >/dev/null 2>&1 || { echo "$(COLOR_RED)✗ AWS CLI not found. Please install it.$(COLOR_RESET)"; exit 1; }
	@command -v $(TERRAFORM) >/dev/null 2>&1 || { echo "$(COLOR_RED)✗ Terraform not found. Please install it.$(COLOR_RESET)"; exit 1; }
	@$(AWS) sts get-caller-identity >/dev/null 2>&1 || { echo "$(COLOR_RED)✗ AWS credentials not configured.$(COLOR_RESET)"; exit 1; }
	@echo "$(COLOR_GREEN)✓ AWS CLI found$(COLOR_RESET)"
	@echo "$(COLOR_GREEN)✓ Terraform found$(COLOR_RESET)"
	@echo "$(COLOR_GREEN)✓ AWS credentials configured$(COLOR_RESET)"
	@echo "$(COLOR_GREEN)✓ All prerequisites met$(COLOR_RESET)"

check-optional: ## Check optional tools (OPA, tfsec, TFLint, Go)
	@echo "$(COLOR_BLUE)Checking optional tools...$(COLOR_RESET)"
	@command -v $(OPA) >/dev/null 2>&1 && echo "$(COLOR_GREEN)✓ OPA found$(COLOR_RESET)" || echo "$(COLOR_YELLOW)⚠ OPA not found (optional for policy tests)$(COLOR_RESET)"
	@command -v $(TFSEC) >/dev/null 2>&1 && echo "$(COLOR_GREEN)✓ tfsec found$(COLOR_RESET)" || echo "$(COLOR_YELLOW)⚠ tfsec not found (optional for security scanning)$(COLOR_RESET)"
	@command -v $(TFLINT) >/dev/null 2>&1 && echo "$(COLOR_GREEN)✓ TFLint found$(COLOR_RESET)" || echo "$(COLOR_YELLOW)⚠ TFLint not found (optional for linting)$(COLOR_RESET)"
	@command -v $(GO) >/dev/null 2>&1 && echo "$(COLOR_GREEN)✓ Go found$(COLOR_RESET)" || echo "$(COLOR_YELLOW)⚠ Go not found (optional for unit tests)$(COLOR_RESET)"

pre-deploy: check-prereqs ## Run pre-deployment validation
	@echo "$(COLOR_BLUE)Running pre-deployment checks...$(COLOR_RESET)"
	@chmod +x scripts/pre-deployment-check.sh
	@./scripts/pre-deployment-check.sh

# ============================================================================
# Terraform Core Commands
# ============================================================================
init: check-prereqs ## Initialize Terraform
	@echo "$(COLOR_BLUE)Initializing Terraform...$(COLOR_RESET)"
	@$(TERRAFORM) init -upgrade
	@echo "$(COLOR_GREEN)✓ Terraform initialized$(COLOR_RESET)"

validate: init ## Validate Terraform configuration
	@echo "$(COLOR_BLUE)Validating Terraform configuration...$(COLOR_RESET)"
	@$(TERRAFORM) validate
	@$(TERRAFORM) fmt -check -recursive
	@echo "$(COLOR_GREEN)✓ Validation passed$(COLOR_RESET)"

format: ## Format Terraform files
	@echo "$(COLOR_BLUE)Formatting Terraform files...$(COLOR_RESET)"
	@$(TERRAFORM) fmt -recursive
	@echo "$(COLOR_GREEN)✓ Files formatted$(COLOR_RESET)"

plan: validate ## Generate Terraform plan
	@echo "$(COLOR_BLUE)Generating Terraform plan...$(COLOR_RESET)"
	@if [ -f "$(TFVARS_FILE)" ]; then \
		$(TERRAFORM) plan -var-file="$(TFVARS_FILE)" -out=tfplan; \
	else \
		echo "$(COLOR_YELLOW)⚠ $(TFVARS_FILE) not found, using default variables$(COLOR_RESET)"; \
		$(TERRAFORM) plan -out=tfplan; \
	fi
	@echo "$(COLOR_GREEN)✓ Plan generated: tfplan$(COLOR_RESET)"

plan-destroy: validate ## Generate Terraform destroy plan
	@echo "$(COLOR_BLUE)Generating Terraform destroy plan...$(COLOR_RESET)"
	@if [ -f "$(TFVARS_FILE)" ]; then \
		$(TERRAFORM) plan -destroy -var-file="$(TFVARS_FILE)" -out=tfplan-destroy; \
	else \
		$(TERRAFORM) plan -destroy -out=tfplan-destroy; \
	fi
	@echo "$(COLOR_GREEN)✓ Destroy plan generated: tfplan-destroy$(COLOR_RESET)"

apply: ## Apply Terraform plan (with confirmation)
	@echo "$(COLOR_YELLOW)⚠️  This will deploy Control Tower (60-90 minutes)$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)⚠️  Ensure you have reviewed the plan first$(COLOR_RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		if [ -f "tfplan" ]; then \
			echo "$(COLOR_BLUE)Applying Terraform plan...$(COLOR_RESET)"; \
			$(TERRAFORM) apply tfplan; \
			echo "$(COLOR_BLUE)Running post-deployment script...$(COLOR_RESET)"; \
			chmod +x scripts/post-deployment.sh; \
			./scripts/post-deployment.sh; \
			echo "$(COLOR_GREEN)✓ Deployment complete$(COLOR_RESET)"; \
		else \
			echo "$(COLOR_RED)✗ No plan file found. Run 'make plan' first.$(COLOR_RESET)"; \
			exit 1; \
		fi \
	else \
		echo "$(COLOR_YELLOW)Deployment cancelled$(COLOR_RESET)"; \
	fi

apply-auto: ## Apply Terraform plan without confirmation (CI/CD)
	@echo "$(COLOR_BLUE)Applying Terraform configuration (auto-approve)...$(COLOR_RESET)"
	@if [ -f "$(TFVARS_FILE)" ]; then \
		$(TERRAFORM) apply -var-file="$(TFVARS_FILE)" -auto-approve; \
	else \
		$(TERRAFORM) apply -auto-approve; \
	fi
	@echo "$(COLOR_GREEN)✓ Applied$(COLOR_RESET)"

destroy: ## Destroy Terraform-managed infrastructure (with double confirmation)
	@echo "$(COLOR_RED)⚠️  WARNING: This will destroy all Control Tower infrastructure!$(COLOR_RESET)"
	@echo "$(COLOR_RED)⚠️  This action is IRREVERSIBLE and will affect all accounts!$(COLOR_RESET)"
	@read -p "Type 'destroy' to confirm: " confirm; \
	if [ "$$confirm" = "destroy" ]; then \
		read -p "Are you ABSOLUTELY sure? [y/N] " -n 1 -r; \
		echo; \
		if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
			if [ -f "$(TFVARS_FILE)" ]; then \
				$(TERRAFORM) destroy -var-file="$(TFVARS_FILE)"; \
			else \
				$(TERRAFORM) destroy; \
			fi; \
		else \
			echo "$(COLOR_YELLOW)Destroy cancelled$(COLOR_RESET)"; \
		fi \
	else \
		echo "$(COLOR_YELLOW)Destroy cancelled$(COLOR_RESET)"; \
	fi

# ============================================================================
# Terraform State Management
# ============================================================================
output: ## Show Terraform outputs
	@$(TERRAFORM) output

output-json: ## Show Terraform outputs in JSON
	@$(TERRAFORM) output -json

state-list: ## List Terraform state resources
	@$(TERRAFORM) state list

state-show: ## Show specific resource from state
	@read -p "Resource name: " resource; \
	$(TERRAFORM) state show $$resource

refresh: ## Refresh Terraform state
	@echo "$(COLOR_BLUE)Refreshing Terraform state...$(COLOR_RESET)"
	@$(TERRAFORM) refresh
	@echo "$(COLOR_GREEN)✓ State refreshed$(COLOR_RESET)"

import: ## Import existing resource
	@read -p "Resource address: " address; \
	read -p "Resource ID: " id; \
	$(TERRAFORM) import $$address $$id

taint: ## Taint a resource for recreation
	@read -p "Resource address: " address; \
	$(TERRAFORM) taint $$address

untaint: ## Untaint a resource
	@read -p "Resource address: " address; \
	$(TERRAFORM) untaint $$address

backup-state: ## Backup Terraform state
	@echo "$(COLOR_BLUE)Backing up state...$(COLOR_RESET)"
	@mkdir -p backups
	@$(TERRAFORM) state pull > backups/terraform.tfstate.$$(date +%Y%m%d_%H%M%S).backup
	@echo "$(COLOR_GREEN)✓ State backed up to backups/$(COLOR_RESET)"

restore-state: ## Restore Terraform state from backup
	@echo "Available backups:"
	@ls -1 backups/
	@read -p "Backup file name: " file; \
	$(TERRAFORM) state push backups/$$file

# ============================================================================
# Testing
# ============================================================================
test: validate ## Run basic validation tests
	@echo "$(COLOR_BLUE)Running basic tests...$(COLOR_RESET)"
	@echo "$(COLOR_GREEN)✓ Validation passed$(COLOR_RESET)"

test-all: ## Run all tests (validation, OPA, unit tests, security)
	@echo "$(COLOR_BLUE)Running complete test suite...$(COLOR_RESET)"
	@chmod +x scripts/validate-all.sh
	@./scripts/validate-all.sh

test-unit: ## Run Terratest unit tests
	@echo "$(COLOR_BLUE)Running Terratest unit tests...$(COLOR_RESET)"
	@command -v $(GO) >/dev/null 2>&1 || { echo "$(COLOR_RED)✗ Go not found. Please install Go 1.21+$(COLOR_RESET)"; exit 1; }
	@chmod +x scripts/run-terraform-tests.sh
	@./scripts/run-terraform-tests.sh

test-opa: ## Run OPA policy tests
	@echo "$(COLOR_BLUE)Running OPA policy tests...$(COLOR_RESET)"
	@command -v $(OPA) >/dev/null 2>&1 || { echo "$(COLOR_RED)✗ OPA not found. Install: brew install opa$(COLOR_RESET)"; exit 1; }
	@chmod +x scripts/run-opa-tests.sh
	@./scripts/run-opa-tests.sh

# ============================================================================
# Security and Compliance
# ============================================================================
security-scan: ## Run security scan with tfsec
	@echo "$(COLOR_BLUE)Running security scan...$(COLOR_RESET)"
	@command -v $(TFSEC) >/dev/null 2>&1 || { echo "$(COLOR_RED)✗ tfsec not found. Install: brew install tfsec$(COLOR_RESET)"; exit 1; }
	@$(TFSEC) . --minimum-severity MEDIUM
	@echo "$(COLOR_GREEN)✓ Security scan complete$(COLOR_RESET)"

lint: ## Run TFLint
	@echo "$(COLOR_BLUE)Running TFLint...$(COLOR_RESET)"
	@command -v $(TFLINT) >/dev/null 2>&1 || { echo "$(COLOR_RED)✗ TFLint not found. Install: brew install tflint$(COLOR_RESET)"; exit 1; }
	@$(TFLINT) --init
	@$(TFLINT) --recursive
	@echo "$(COLOR_GREEN)✓ Linting complete$(COLOR_RESET)"

check-drift: ## Check for configuration drift
	@echo "$(COLOR_BLUE)Checking for drift...$(COLOR_RESET)"
	@$(TERRAFORM) plan -detailed-exitcode || echo "$(COLOR_YELLOW)⚠️  Drift detected!$(COLOR_RESET)"

# ============================================================================
# Documentation and Utilities
# ============================================================================
docs: ## Generate documentation
	@echo "$(COLOR_BLUE)Generating documentation...$(COLOR_RESET)"
	@command -v terraform-docs >/dev/null 2>&1 || { echo "$(COLOR_YELLOW)⚠ terraform-docs not found. Install: brew install terraform-docs$(COLOR_RESET)"; exit 1; }
	@terraform-docs markdown table --output-file README_TERRAFORM.md .
	@echo "$(COLOR_GREEN)✓ Documentation generated: README_TERRAFORM.md$(COLOR_RESET)"

graph: ## Generate Terraform dependency graph
	@echo "$(COLOR_BLUE)Generating dependency graph...$(COLOR_RESET)"
	@command -v dot >/dev/null 2>&1 || { echo "$(COLOR_RED)✗ Graphviz not found. Install: brew install graphviz$(COLOR_RESET)"; exit 1; }
	@$(TERRAFORM) graph | dot -Tpng > graph.png
	@echo "$(COLOR_GREEN)✓ Graph saved to graph.png$(COLOR_RESET)"

cost-estimate: ## Estimate costs with Infracost
	@echo "$(COLOR_BLUE)Estimating costs...$(COLOR_RESET)"
	@command -v infracost >/dev/null 2>&1 || { echo "$(COLOR_RED)✗ Infracost not found. Install: brew install infracost$(COLOR_RESET)"; exit 1; }
	@infracost breakdown --path .
	@echo "$(COLOR_GREEN)✓ Cost estimate complete$(COLOR_RESET)"

version: ## Show versions
	@echo "$(COLOR_BLUE)Tool Versions:$(COLOR_RESET)"
	@echo "Terraform: $$($(TERRAFORM) version | head -n1)"
	@echo "AWS CLI: $$($(AWS) --version)"
	@command -v $(OPA) >/dev/null 2>&1 && echo "OPA: $$($(OPA) version | head -n1)" || echo "OPA: not installed"
	@command -v $(GO) >/dev/null 2>&1 && echo "Go: $$($(GO) version)" || echo "Go: not installed"
	@command -v $(TFSEC) >/dev/null 2>&1 && echo "tfsec: $$($(TFSEC) --version)" || echo "tfsec: not installed"
	@command -v $(TFLINT) >/dev/null 2>&1 && echo "TFLint: $$($(TFLINT) --version)" || echo "TFLint: not installed"

# ============================================================================
# Workspace Management
# ============================================================================
workspace-list: ## List Terraform workspaces
	@$(TERRAFORM) workspace list

workspace-new: ## Create new Terraform workspace
	@read -p "Workspace name: " name; \
	$(TERRAFORM) workspace new $$name

workspace-select: ## Select Terraform workspace
	@read -p "Workspace name: " name; \
	$(TERRAFORM) workspace select $$name

# ============================================================================
# Cleanup
# ============================================================================
clean: ## Clean Terraform files
	@echo "$(COLOR_BLUE)Cleaning Terraform files...$(COLOR_RESET)"
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@rm -f tfplan tfplan-destroy
	@rm -f terraform.tfstate terraform.tfstate.backup
	@rm -f graph.png
	@echo "$(COLOR_GREEN)✓ Cleaned$(COLOR_RESET)"

clean-all: clean ## Clean all generated files including backups
	@echo "$(COLOR_BLUE)Cleaning all generated files...$(COLOR_RESET)"
	@rm -rf backups/
	@rm -f README_TERRAFORM.md
	@echo "$(COLOR_GREEN)✓ All cleaned$(COLOR_RESET)"

# ============================================================================
# CI/CD Targets
# ============================================================================
ci: init validate lint security-scan test-opa plan ## CI pipeline
	@echo "$(COLOR_GREEN)✓ CI pipeline completed$(COLOR_RESET)"

cd: apply-auto ## CD pipeline
	@echo "$(COLOR_GREEN)✓ CD pipeline completed$(COLOR_RESET)"

# ============================================================================
# Advanced Operations
# ============================================================================
console: ## Open Terraform console
	@$(TERRAFORM) console

upgrade-modules: ## Upgrade Terraform modules
	@echo "$(COLOR_BLUE)Upgrading modules...$(COLOR_RESET)"
	@$(TERRAFORM) init -upgrade
	@echo "$(COLOR_GREEN)✓ Modules upgraded$(COLOR_RESET)"

lock: ## Force unlock Terraform state
	@read -p "Lock ID: " lockid; \
	$(TERRAFORM) force-unlock $$lockid
