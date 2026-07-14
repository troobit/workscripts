resource "azurerm_log_analytics_workspace" "this" {
  name                       = "aueast-logs"
  location                   = var.location
  resource_group_name        = local.rg_name
  sku                        = "PerGB2018" # "Free" sku was retired by Azure and rejected by current azurerm providers
  retention_in_days          = 30
  internet_ingestion_enabled = false
  depends_on = [
    azurerm_resource_group.this,
    azurerm_storage_account.this
  ]
}
