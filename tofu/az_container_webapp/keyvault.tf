# =============================================================================
# Key Vault
# =============================================================================

resource "azurerm_key_vault" "this" {
  name                          = "kv-this"
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  enabled_for_disk_encryption   = false
  tenant_id                     = data.azurerm_client_config.this.tenant_id
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  public_network_access_enabled = true
  tags                          = var.common_tags
}

# =============================================================================
# Allowing TF agent access to KV
# =============================================================================

resource "azurerm_role_assignment" "kv_administrator" {
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.this.object_id
  scope                = azurerm_key_vault.this.id
  depends_on           = [azurerm_key_vault.this]
}

# Removing KV Access admin for TF agent - as it is inherited from subscription level
# resource "azurerm_role_assignment" "kv_data_access_administrator" {
#   scope                = azurerm_key_vault.this.id
#   role_definition_name = "Key Vault Data Access Administrator"
#   principal_id         = data.azurerm_client_config.this.object_id
#   depends_on           = [azurerm_key_vault.this]
# }

# =============================================================================
# Key Vault Secrets
# =============================================================================

resource "azurerm_key_vault_secret" "cr-password" {
  name         = "cr-password"
  value        = var.cr_password
  key_vault_id = azurerm_key_vault.this.id
  depends_on = [
    azurerm_key_vault.this,
    azurerm_role_assignment.kv_administrator
    # azurerm_role_assignment.kv_data_access_administrator
  ]
  lifecycle {
    ignore_changes = [
      tags["file-encoding"],
      value
    ]
  }
}
