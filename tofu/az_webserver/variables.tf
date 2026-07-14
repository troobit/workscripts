# =============================================================================
# Common Variables
# =============================================================================

variable "subscription_id" {
  type = string
  #default = "00000000-0000-0000-0000-000000000000"
}

variable "common_tags" {
  type    = map(any)
  default = { "Project" = "ProjectNames" }
}

variable "location" {
  type = string
  #default = "australiaeast"
}