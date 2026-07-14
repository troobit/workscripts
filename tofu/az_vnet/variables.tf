variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
  # default = {
  #   "Project"     = "ProjectNames",
  #   "cost-center" = "cc01",
  #   "costCenter"  = "CC02"
  # }
}

variable "location_primary" {
  type    = string
  default = "australiaeast"
}
