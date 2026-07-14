# =============================================================================
# Container App Environment
# =============================================================================

resource "azurerm_container_app_environment" "this" {
  name                = "cappenv-this"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.common_tags
}
# =============================================================================
# Container App UMID (for Keyvault access)
# =============================================================================

module "ca_umid" {
  source              = "./modules/umid"
  name                = "kv-access"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  role_assignments = [
    {
      role_definition_name = "Key Vault Secrets User"
      scope                = azurerm_key_vault.this.id
    }
  ]
}

# =============================================================================
# Container App Base (updated by application pipelines)
# =============================================================================
module "containerapp" {
  for_each                  = { for k, v in var.container_apps : k => v }
  name                      = "this"
  source                    = "./modules/containerapp"
  app_config                = each.value
  key_vault_uri             = azurerm_key_vault.this.vault_uri
  resource_group_name       = azurerm_resource_group.this.name
  container_app_env_id      = azurerm_container_app_environment.this.id
  cr-password-secret-id     = azurerm_key_vault_secret.cr-password.versionless_id
  user_managed_resource_ids = [module.ca_umid.id]
  user_managed_client_ids   = [module.ca_umid.client_id]
  custom_domain             = "this.com.au"
  depends_on                = [azurerm_key_vault_secret.cr-password, azurerm_container_app_environment.this]
}
