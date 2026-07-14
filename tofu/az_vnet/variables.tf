variable "subscription_id" {
  type    = string
  default = "95991215-8f22-4b25-919c-451d98526ef3"
}

variable "tenant_id" {
  type    = string
  default = "6b7d3a1d-4be6-417f-929f-37b0119ba799"
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
