# =============================================================================
# Data Sources
# =============================================================================

data "azurerm_client_config" "this" {}

# =============================================================================
# Resource Groups
# =============================================================================

resource "azurerm_resource_group" "this" {
  name     = "rg-this"
  location = "australiaeast"
  tags     = var.common_tags
}

# =============================================================================
# Virtual Networks
# =============================================================================
module "vnet" {
  for_each            = var.vnet_config
  source              = "./modules/vnet"
  vnet_name           = each.key
  vnet_cidr           = each.value.vnet_cidr
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnets             = each.value.subnets
  tags                = var.common_tags
}


