# =============================================================================
# Common Variables
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

variable "adminusername" {
  description = "What the default username for vm's deployed should be"
  default     = "osadmin"
}

/*
For use in an auto.tfvars file
auto_approval_subscription_ids = "[]"
visibility_subscription_ids = "[]"
location = ""
ws_default_subnet_name = ""
ws_vnet_name = ""
password = ""
*/
variable "jh_count" {
  description = "Number of jump host NICs to create."
  type        = number
  # mirrors the declaration in the disabled jumphost.tf.ignore
  default = 1
}

variable "private_link_service_alias" {
  description = "Alias of the private link service to connect to (output of the az_pep_service root)."
  type        = string
  default     = ""
}
