# ====================================================================================
# Variables
# ====================================================================================

variable "hub_vnet_name" {
  default = "hub-vnet"
}

variable "hub_vnet_CIDR" {
  default = ["10.0.0.0/16"]
}

variable "hub_subnet1_CIDR" {
  default = ["10.0.0.0/24"]
}

variable "hub_bastion_CIDR" {
  default = ["10.0.255.192/26"]
}

# ====================================================================================
# HUB VNET (and subnets)
# ====================================================================================

resource "azurerm_virtual_network" "hub-vnet" {
  name                = var.hub_vnet_name
  location            = var.location_primary
  resource_group_name = var.rg_name
  address_space       = var.hub_vnet_CIDR
  tags                = merge(var.common_tags, { "Resource Type" = "vnet" })
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "hub-subnet-01" {
  name                 = "subnet-01"
  address_prefixes     = var.hub_subnet1_CIDR
  virtual_network_name = var.hub_vnet_name
  resource_group_name  = var.rg_name
  depends_on = [
    azurerm_virtual_network.hub-vnet
  ]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  address_prefixes     = var.hub_bastion_CIDR
  virtual_network_name = var.hub_vnet_name
  resource_group_name  = var.rg_name
  depends_on = [
    azurerm_virtual_network.hub-vnet
  ]
}
