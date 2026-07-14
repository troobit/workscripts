variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "common_tags" {
  type    = map(any)
  default = { "Project" = "ProjectNames" }
}

variable "location_primary" {
  type    = string
  default = "australiaeast"
}
