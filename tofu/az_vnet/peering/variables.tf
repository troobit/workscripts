variable "subscription_id" {
  type    = string
  default = "19acb693-f70d-4476-9cdb-ecd9dfc0600e"
}

variable "tenant_id" {
  type    = string
  default = "6b7d3a1d-4be6-417f-929f-37b0119ba799"
}

variable "common_tags" {
  type    = map(any)
  default = { "Project" = "ProjectNames" }
}

variable "location_primary" {
  type    = string
  default = "australiaeast"
}
