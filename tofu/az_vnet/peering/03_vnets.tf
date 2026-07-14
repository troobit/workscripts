# ====================================================================================
# Data feed from YAML file
# ====================================================================================
locals {
  vnet_data = yamldecode(file("./config/networks.yml"))

  # flatten ensures that this local value is a flat list of objects, rather
  # than a list of lists of objects.
  vnets = flatten([
    for vnet_key, vnet in local.vnet_data : [
      {
        name     = vnet.name
        location = vnet.location
        cidr     = vnet.cidr
      }
    ]
  ])

  subnets = flatten([
    for vnet_key, vnet in local.vnet_data : [
      for subnet_key, subnet in vnet.subnets : [
        {
          vnet = vnet.name
          name = subnet.name
          cidr = subnet.cidr
        }
      ]
    ]
  ])
}
# ====================================================================================
# VNETS
# ====================================================================================

resource "azurerm_virtual_network" "this" {
  # for_each block needs a map, so the for element creates a map with the name as the keys
  for_each            = { for k, v in local.vnets : v.name => v }
  name                = each.key
  address_space       = [each.value.cidr]
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "this" {
  for_each             = { for k, v in local.subnets : "${v.vnet}-${v.name}" => v }
  name                 = each.value.name
  address_prefixes     = [each.value.cidr]
  virtual_network_name = azurerm_virtual_network.this[each.value.vnet].name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network_peering" "this" {

  name                         = "spoke1-hub-peer"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.this["spoke1-vnet"].name
  remote_virtual_network_id    = azurerm_virtual_network.this["hub-vnet"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network.this]
}
