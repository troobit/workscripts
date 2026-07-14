resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = local.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on = [
    azurerm_resource_group.this
  ]
}

resource "azurerm_log_analytics_linked_storage_account" "this" {
  data_source_type      = "CustomLogs"
  resource_group_name   = azurerm_resource_group.this.name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  storage_account_ids   = [azurerm_storage_account.this.id]
  depends_on = [
    azurerm_resource_group.this,
    azurerm_storage_account.this,
    azurerm_log_analytics_workspace.this
  ]
}
