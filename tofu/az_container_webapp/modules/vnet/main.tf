# =============================================================================
# Virtual Network
# =============================================================================

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# =============================================================================
# Virtual Network - Subnets
# =============================================================================

resource "azurerm_subnet" "this" {
  for_each             = var.subnets
  name                 = "sn-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = each.value.service_delegation
    content {
      name = each.value
      service_delegation {
        name    = each.value
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}

# =============================================================================
# Virtual Network - Network Security Groups
# =============================================================================

resource "azurerm_network_security_group" "this" {
  for_each            = var.subnets
  name                = "nsg-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = var.subnets
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}