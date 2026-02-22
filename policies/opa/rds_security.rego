# OPA RDS Security Policies
package terraform.controltower.rds

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.terraform.controltower.helpers

# ============================================================================
# RDS Public Access Policies
# ============================================================================

# POLICY: RDS instances must not be publicly accessible
deny[msg] {
    rds := helpers.resources_by_type("aws_db_instance")[_]
    rds.values.publicly_accessible == true
    msg := sprintf("RDS instance '%s' must not be publicly accessible", [rds.address])
}

# ============================================================================
# RDS Backup Policies
# ============================================================================

# POLICY: RDS instances must have backup retention
deny[msg] {
    rds := helpers.resources_by_type("aws_db_instance")[_]
    rds.values.backup_retention_period < 7
    msg := sprintf("RDS instance '%s' must have backup retention period of at least 7 days", [rds.address])
}

# ============================================================================
# RDS High Availability Policies
# ============================================================================

# POLICY: Production RDS instances must be Multi-AZ
deny[msg] {
    rds := helpers.resources_by_type("aws_db_instance")[_]
    helpers.is_production(rds)
    not rds.values.multi_az
    msg := sprintf("Production RDS instance '%s' must be Multi-AZ", [rds.address])
}

# POLICY: RDS instances must have deletion protection in production
deny[msg] {
    rds := helpers.resources_by_type("aws_db_instance")[_]
    helpers.is_production(rds)
    not rds.values.deletion_protection
    msg := sprintf("Production RDS instance '%s' must have deletion protection enabled", [rds.address])
}
