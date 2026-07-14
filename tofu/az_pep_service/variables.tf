# =============================================================================
# Common Variables that are used across all resources
# =============================================================================

variable "common_tags" {
  type = map(any)
  default = { "Project" = "Private Link service"
    "OpenTofu"    = "true"
    "Environment" = "dev"
  "CostCentre" = "CC-OB1234" }
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "password" {
  description = "Default password for vm's deployed."
  sensitive   = true
}

variable "auto_approval_subscription_ids" {
  description = "What subscription IDs are allowed to automatically connect to the private link service (without explicit approval)?"
  default     = ["19acb693-f70d-4476-9cdb-ecd9dfc0600e", "0e09522e-d97d-418d-b52d-068d0728e526"]
}

variable "visibility_subscription_ids" {
  description = "What subscription IDs can SEE the private link service?"
  default     = ["19acb693-f70d-4476-9cdb-ecd9dfc0600e", "0e09522e-d97d-418d-b52d-068d0728e526"]
}
