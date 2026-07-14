variable "common_tags" {
  type = map(any)
  default = {
    "createdBy" = "OpenTofu"
    "project"   = "this"
  }
}

variable "vnet_config" {
  type = map(object({
    vnet_cidr = string
    subnets = map(object({
      address_prefixes   = set(string)
      service_delegation = set(string)
    }))
  }))
  description = "Map of vnet configuration"
  default     = {}
}

# =============================================================================
# Container Apps
# =============================================================================
variable "container_apps" {
  type = list(object({
    name          = string
    revision_mode = string
    template = object({
      container = object({
        name   = string
        image  = string
        cpu    = number
        memory = string
      })
    })
  }))
  default     = []
  description = "Container application config as defined for azurerm_container_app in the azurerm provider docs."
}

variable "container_app_env_vars" {
  type    = map(string)
  default = {}
}

variable "cr_password" {
  type      = string
  default   = "value"
  sensitive = true
}
