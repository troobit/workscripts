output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "kv_id" {
  value = azurerm_key_vault.this.id
}

output "kv_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "umid_id" {
  value = module.ca_umid.id
}

output "container_app_env_id" {
  value = azurerm_container_app_environment.this.id
}
