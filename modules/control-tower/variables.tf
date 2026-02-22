variable "governed_regions" {
  description = "List of regions governed by Control Tower"
  type        = list(string)
}

variable "landing_zone_version" {
  description = "Control Tower landing zone version"
  type        = string
  default     = "3.3"
}
