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
  type        = list(string)
  # real subscription IDs belong in a local tfvars file — see example.tfvars
  default = []
}

variable "visibility_subscription_ids" {
  description = "What subscription IDs can SEE the private link service?"
  type        = list(string)
  # real subscription IDs belong in a local tfvars file — see example.tfvars
  default = []
}

variable "endpointsvc_count" {
  description = "Number of endpoint NICs to create behind the load balancer."
  type        = number
  # matches app_server_count so each app server vm gets a nic
  default = 2
}
