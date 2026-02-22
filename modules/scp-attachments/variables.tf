variable "policy_attachments" {
  description = "Map of policy attachments"
  type = map(object({
    policy_id = string
    target_id = string
  }))
}
