variable "parent_id" {
  description = "Parent organizational unit ID"
  type        = string
}

variable "organizational_units" {
  description = "Map of organizational units to create"
  type = map(object({
    name        = string
    environment = string
    tags        = map(string)
  }))
}
