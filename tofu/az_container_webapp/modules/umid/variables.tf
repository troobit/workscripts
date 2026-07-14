variable "common_tags" {
  type = map(any)
  default = {
    "createdBy" = "Terraform"
  }
}

variable "role_assignments" {
  type = list(object({
    role_definition_name = string
    scope                = string
  }))
  default = []
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "name" {
  type        = string
  description = "The name (suffix) of the user managed identity"
}

variable "location" {
  type        = string
  description = "The location of the resource"
}
