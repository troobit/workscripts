# =============================================================================
# Common Variables
# =============================================================================

variable "subscription_id" {
  type = string
  #default = "d79193eb-3ccd-4b78-ae11-0c0507247e5b"
}

variable "tenant_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "common_tags" {
  type    = map(any)
  default = { "Project" = "Logging" }
}

variable "location" {
  type = string
  #default = "australiaeast"
}
