# =============================================================================
# Outputs
# =============================================================================

output "user_object_ids" {
  description = "Object IDs of managed users, keyed by their short name"
  value       = { for k, u in azuread_user.this : k => u.object_id }
}

output "group_object_ids" {
  description = "Object IDs of managed groups, keyed by their short name"
  value       = { for k, g in azuread_group.this : k => g.object_id }
}
