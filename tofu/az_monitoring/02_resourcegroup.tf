locals {
  rg_name = "LogAnalytics-${var.location}"
}

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.location
}
