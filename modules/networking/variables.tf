variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "inspection_vpc_cidr" {
  description = "CIDR block for inspection VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "transit_gateway_asn" {
  description = "ASN for Transit Gateway"
  type        = number
  default     = 64512

  validation {
    condition     = var.transit_gateway_asn >= 64512 && var.transit_gateway_asn <= 65534
    error_message = "Transit Gateway ASN must be in private ASN range (64512-65534)."
  }
}

variable "allowed_domains" {
  description = "List of allowed domains for Network Firewall"
  type        = list(string)
  default     = []
}

variable "denied_domains" {
  description = "List of denied domains for Network Firewall"
  type        = list(string)
  default     = []
}

variable "dns_blocked_domains" {
  description = "List of domains to block via DNS Firewall"
  type        = list(string)
  default     = []
}

variable "dns_allowed_domains" {
  description = "List of domains to explicitly allow via DNS Firewall"
  type        = list(string)
  default     = []
}

variable "log_bucket_name" {
  description = "S3 bucket name for logs"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 90
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
}

variable "nat_gateway_bandwidth_threshold" {
  description = "NAT Gateway bandwidth threshold in bytes"
  type        = number
  default     = 10737418240 # 10 GB
}

variable "firewall_packet_drop_threshold" {
  description = "Network Firewall packet drop threshold"
  type        = number
  default     = 1000
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
