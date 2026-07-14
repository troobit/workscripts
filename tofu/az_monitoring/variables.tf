# =============================================================================
# Common Variables
# =============================================================================

variable "subscription_id" {
  type = string
  #default = "00000000-0000-0000-0000-000000000000"
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

variable "storage_account_name" {
  description = "Globally unique name of the storage account used for custom log storage."
  type        = string
}
