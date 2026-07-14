# =============================================================================
# Locals
# =============================================================================

locals {
  name = "mi-${var.name}"
}

# =============================================================================
# User Managed Identities
# =============================================================================

resource "azurerm_user_assigned_identity" "this" {
  name                = local.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = merge(var.common_tags, {
    "repository" = "troobit/this" # For using in the Azure DevOps pipeline when different repos deploy to the same RG
  })
}

resource "azurerm_role_assignment" "this" {
  for_each = {
    for k, v in var.role_assignments : v.role_definition_name => v
  }
  role_definition_name = each.key
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  scope                = each.value.scope
}
