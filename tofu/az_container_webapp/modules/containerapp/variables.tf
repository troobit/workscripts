variable "common_tags" {
  type = map(any)
  default = {
    "env"       = null
    "createdBy" = "OpenTofu"
  }
}

variable "custom_domain" {
  type        = string
  description = "The custom domain to be used by the container app"
  default     = null
}

variable "user_managed_resource_ids" {
  type = list(string)
}

variable "user_managed_client_ids" {
  type        = list(string)
  description = "The client IDs of the user managed identities to be used by the container app"
}

variable "cr-password-secret-id" {
  type        = string
  description = "The ID of the secret in the Key Vault that contains the Container Registry password or string"
}

variable "name" {
  type        = string
  description = "The name of the container app"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

# variable "cr_login_server" {
#   type        = string
#   description = "The login server of the Container Registry"
# }

variable "key_vault_uri" {
  type        = string
  description = "The URI of the Key Vault this container app will reference for secrets"
}

variable "container_app_env_id" {
  type        = string
  description = "The ID of the container app environment to be used by the container apps"
}

variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "app_config" {
  type = object({
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
  })
  description = "Container application config as defined for azurerm_container_app in the azurerm provider docs."
}
