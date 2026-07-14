# =============================================================================
# Locals
# =============================================================================

locals {
  # one membership pair per (user, group) so azuread_group_member can
  # for_each over a flat map
  group_memberships = {
    for pair in flatten([
      for user_key, user in var.users : [
        for group_key in user.groups : {
          key       = "${user_key}-${group_key}"
          user_key  = user_key
          group_key = group_key
        }
      ]
    ]) : pair.key => pair
  }

  # flatten the per-principal role_assignments lists into flat maps, the
  # same data-driven pattern as the umid module's role assignments
  user_role_assignments = {
    for pair in flatten([
      for user_key, user in var.users : [
        for ra in user.role_assignments : {
          key                  = "${user_key}-${ra.role_definition_name}"
          principal_key        = user_key
          role_definition_name = ra.role_definition_name
          scope                = ra.scope
        }
      ]
    ]) : pair.key => pair
  }

  group_role_assignments = {
    for pair in flatten([
      for group_key, group in var.groups : [
        for ra in group.role_assignments : {
          key                  = "${group_key}-${ra.role_definition_name}"
          principal_key        = group_key
          role_definition_name = ra.role_definition_name
          scope                = ra.scope
        }
      ]
    ]) : pair.key => pair
  }

  # every distinct role referenced anywhere gets activated exactly once
  directory_role_names = toset(concat(
    [for ra in values(local.user_role_assignments) : ra.role_definition_name],
    [for ra in values(local.group_role_assignments) : ra.role_definition_name],
  ))
}

# =============================================================================
# Users
# =============================================================================

resource "random_password" "initial" {
  for_each = var.users

  length  = 24
  special = true
}

resource "azuread_user" "this" {
  for_each = var.users

  user_principal_name = "${each.value.mail_nickname}@${var.tenant_domain}"
  display_name        = each.value.display_name
  mail_nickname       = each.value.mail_nickname

  # throwaway initial credential; the user must replace it at first sign-in
  password              = random_password.initial[each.key].result
  force_password_change = true
}

# =============================================================================
# Groups
# =============================================================================

resource "azuread_group" "this" {
  for_each = var.groups

  display_name     = each.value.display_name
  description      = each.value.description
  security_enabled = true
  # only role-assignable groups can hold directory roles
  assignable_to_role = each.value.assignable_to_role
}

resource "azuread_group_member" "this" {
  for_each = local.group_memberships

  group_object_id  = azuread_group.this[each.value.group_key].object_id
  member_object_id = azuread_user.this[each.value.user_key].object_id
}

# =============================================================================
# Directory Role Assignments
# =============================================================================

# built-in roles are dormant until activated in the tenant
resource "azuread_directory_role" "this" {
  for_each = local.directory_role_names

  display_name = each.value
}

resource "azuread_directory_role_assignment" "users" {
  for_each = local.user_role_assignments

  role_id             = azuread_directory_role.this[each.value.role_definition_name].template_id
  principal_object_id = azuread_user.this[each.value.principal_key].object_id
  directory_scope_id  = each.value.scope
}

resource "azuread_directory_role_assignment" "groups" {
  for_each = local.group_role_assignments

  role_id             = azuread_directory_role.this[each.value.role_definition_name].template_id
  principal_object_id = azuread_group.this[each.value.principal_key].object_id
  directory_scope_id  = each.value.scope
}
