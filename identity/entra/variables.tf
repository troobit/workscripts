# =============================================================================
# Tenant
# =============================================================================

variable "tenant_id" {
  type        = string
  description = "GUID of the existing Entra ID tenant to configure"
}

variable "tenant_domain" {
  type        = string
  description = "Primary domain used to build user principal names, e.g. example.onmicrosoft.com"
}

# =============================================================================
# Users
# =============================================================================

variable "users" {
  type = map(object({
    display_name  = string
    mail_nickname = string
    # keys into var.groups this user should be a member of
    groups = optional(list(string), [])
    # data-driven directory-role assignments; scope "/" means tenant-wide
    role_assignments = optional(list(object({
      role_definition_name = string
      scope                = string
    })), [])
  }))
  description = "Users to create, keyed by a stable short name"
  default     = {}
}

# =============================================================================
# Groups
# =============================================================================

variable "groups" {
  type = map(object({
    display_name = string
    description  = optional(string, "Managed by OpenTofu")
    # must be true for the group to receive directory-role assignments
    assignable_to_role = optional(bool, false)
    role_assignments = optional(list(object({
      role_definition_name = string
      scope                = string
    })), [])
  }))
  description = "Security groups to create, keyed by a stable short name"
  default     = {}
}
