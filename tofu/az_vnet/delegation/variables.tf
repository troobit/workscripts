variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "env_name" {
  type    = string
  default = "dev"
}

variable "common_tags" {
  type    = map(any)
  default = { "Project" = "ProjectNames" }
}

variable "location_primary" {
  type    = string
  default = "australiaeast"
}
