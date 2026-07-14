# ====================================================================================
# This section goes through creating the virtual network for the jump host(s), the
# private links, and the public IP address to facilitate the bastion connections to 
# jump hosts
# ====================================================================================

# ====================================================================================
# Variables
# ====================================================================================

variable "ingress_vnet_name" {
  default = "ingress_vnet"  
}

variable "ingress_vnet_CIDR" {
  default = ["10.0.0.0/16"]
}

variable "bastion_CIDR" {
  default = ["10.0.200.0/24"]
}

variable "jumphost_CIDR" {
  default = ["10.0.0.0/24"]
}

variable "privatelink_CIDR" {
  default = ["10.0.1.0/24"]
}

# ====================================================================================
# VNETs (and subnets)
# ====================================================================================

resource "azurerm_virtual_network" "ingress_vnet" {
  name                = var.ingress_vnet_name
  location            = var.location
  resource_group_name = var.ingress_rg_name
  address_space       = var.ingress_vnet_CIDR
  tags = merge(var.common_tags, {"Resource Type" = "vnet"})

  depends_on = [azurerm_resource_group.ingress_rg]
}

resource "azurerm_subnet" "bastion" {
  name           = "AzureBastionSubnet"
  address_prefixes = var.bastion_CIDR
  virtual_network_name = var.ingress_vnet_name
  resource_group_name = var.ingress_rg_name
  depends_on = [
    azurerm_virtual_network.ingress_vnet
  ]
}

resource "azurerm_subnet" "jumphosts" {
  name           = "jumphost-vnet"
  address_prefixes = var.jumphost_CIDR
  virtual_network_name = var.ingress_vnet_name
  resource_group_name = var.ingress_rg_name
  depends_on = [
    azurerm_virtual_network.ingress_vnet
  ]
}

resource "azurerm_subnet" "privatelinks" {
  name           = "PrivateLink"
  address_prefixes = var.privatelink_CIDR
  virtual_network_name = var.ingress_vnet_name
  resource_group_name = var.ingress_rg_name
  depends_on = [
    azurerm_virtual_network.ingress_vnet
  ]
}

# ====================================================================================
# NICs
# ====================================================================================

resource "azurerm_network_interface" "jh_nic" {
  count = var.jh_count
  name                           = "jh-nic-${format("%02d", count.index + 1)}"
  location                       = var.location
  resource_group_name            = var.ingress_rg_name

  ip_configuration {
    name                         = "ws-ipconfig"
    subnet_id                    = azurerm_subnet.jumphosts.id
    private_ip_address_allocation = "Dynamic"
    #private_ip_address           = var.private_ip
    #public_ip_address_id         = azurerm_public_ip.pip.id
  }
}

# ====================================================================================
# PIPs 
# ====================================================================================

resource "azurerm_public_ip" "bastion" {
  name                = "bastion-pip"
  resource_group_name = azurerm_resource_group.ingress_rg.name
  location            = var.location
  allocation_method   = "Static"
  sku = "Standard"
  tags = var.common_tags
  depends_on = [
    azurerm_resource_group.ingress_rg,
    azurerm_virtual_network.ingress_vnet]
}

# ====================================================================================
# Bastion Host
# ====================================================================================

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-host"
  location            = var.location
  resource_group_name = azurerm_resource_group.ingress_rg.name

  ip_configuration {
    name                 = "bastionIPconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}