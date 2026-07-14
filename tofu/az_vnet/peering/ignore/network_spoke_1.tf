# ====================================================================================
# Variables
# ====================================================================================

variable "spoke_vnet_name" {
  default = "spoke-vnet"
}

variable "spoke_vnet_CIDR" {
  default = ["10.1.0.0/16"]
}

variable "spoke_subnet1_CIDR" {
  default = ["10.1.0.0/24"]
}

# ====================================================================================
# SPOKE VNET (and subnets)
# ====================================================================================

resource "azurerm_virtual_network" "spoke-vnet" {
  name                = var.spoke_vnet_name
  location            = var.location_primary
  resource_group_name = var.rg_name
  address_space       = var.spoke_vnet_CIDR
  tags                = merge(var.common_tags, { "Resource Type" = "vnet" })
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "spoke-subnet-01" {
  name                 = "subnet-01"
  address_prefixes     = var.spoke_subnet1_CIDR
  virtual_network_name = var.spoke_vnet_name
  resource_group_name  = var.rg_name
  depends_on = [
    azurerm_virtual_network.spoke-vnet
  ]
}
