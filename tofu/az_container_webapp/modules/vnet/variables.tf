variable "vnet_name" {
  type        = string
  description = "The name of the virtual network"
}

variable "vnet_cidr" {
  type = string
  validation {
    condition     = can(regex("^(\\d{1,3}\\.){3}\\d{1,3}/\\d{1,2}$", var.vnet_cidr))
    error_message = "CIDR block must be in the format of x.x.x.x/x"
  }
}

variable "subnets" {
  type = map(object({
    address_prefixes   = set(string)
    service_delegation = set(string)
  }))
  description = "Address prefixes and optional service delegations for each subnet"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group to which the vnet will be deployed"
}

variable "location" {
  type        = string
  description = "The name of the location which the vnet will be deployed"
}

variable "tags" {
  type = map(any)
}