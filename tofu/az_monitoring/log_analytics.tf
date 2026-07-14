resource "azurerm_log_analytics_workspace" "this" {
  name                       = "aueast-logs"
  location                   = var.location
  resource_group_name        = local.rg_name
  sku                        = "Free"
  retention_in_days          = 30
  internet_ingestion_enabled = false
  depends_on = [
    azurerm_resource_group.this,
    azurerm_storage_account.this
  ]
}
