# ====================================================================================
# SPOKE 1
# ====================================================================================

resource "azurerm_virtual_network_peering" "hub-spoke1-peer" {
  name                         = "spoke1-hub-peer"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network.spoke-vnet, azurerm_virtual_network.hub-vnet]
}

resource "azurerm_virtual_network_peering" "spoke1-hub-peer" {
  name                         = "spoke1-hub-peer"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.spoke-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network.spoke-vnet, azurerm_virtual_network.hub-vnet]
}
