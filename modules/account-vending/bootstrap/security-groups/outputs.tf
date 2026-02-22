output "security_group_ids" {
  description = "Map of security group names to IDs"
  value = {
    ssh      = aws_security_group.ssh.id
    https    = aws_security_group.https.id
    http     = aws_security_group.http.id
    internal = aws_security_group.internal.id
    database = aws_security_group.database.id
    alb      = aws_security_group.alb.id
  }
}

output "ssh_security_group_id" {
  description = "SSH security group ID"
  value       = aws_security_group.ssh.id
}

output "https_security_group_id" {
  description = "HTTPS security group ID"
  value       = aws_security_group.https.id
}

output "internal_security_group_id" {
  description = "Internal security group ID"
  value       = aws_security_group.internal.id
}
