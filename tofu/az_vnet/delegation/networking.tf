# =============================================================================
# VARIABLE DEFINITION
# =============================================================================

locals {
  vnet_name     = "example-${var.env_name}-vnet"
  publicip_name = "example-${var.env_name}-pip"
  bastion_name  = "example-${var.env_name}-bastion"
  nsg_name      = "internal-nsg"
  vnet_cidr     = [" 	10.140.64.0/22"]
  subnets = tomap({
    "example-${var.env_name}-database-sn" = {
      address_prefixes   = ["10.140.64.0/24"]
      service_delegation = []
    }
    "PowerBI" = {
      address_prefixes   = ["10.140.67.0/26"]
      service_delegation = ["Microsoft.PowerPlatform/vnetaccesslinks"]
    }
    "AzureBastionSubnet" = {
      address_prefixes   = ["10.140.67.64/26"]
      service_delegation = []
    }
  })
}

# =============================================================================
# VNETS and SUBNETS
# =============================================================================

resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  location            = var.location_primary
  resource_group_name = azurerm_resource_group.resourcegroup.name
  address_space       = ["10.140.64.0/20"]
  tags                = var.common_tags
}

resource "azurerm_subnet" "this" {
  for_each             = local.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes

  # Dynamic blocks support conditionally adding resource variables
  # This is conditional on the existance of service delegation(s)
  dynamic "delegation" {
    for_each = each.value.service_delegation
    content {
      name = delegation.value
      service_delegation {
        name    = delegation.value
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# =============================================================================
# NSGs and ASSOCIATIONS
# =============================================================================

resource "azurerm_network_security_group" "nsg" {
  name                = local.nsg_name
  location            = var.location_primary
  resource_group_name = azurerm_resource_group.resourcegroup.name
  tags                = var.common_tags
}

resource "azurerm_subnet_network_security_group_association" "internal_subnet_nsg" {
  subnet_id                 = azurerm_subnet.this["example-${var.env_name}-database-sn"].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# =============================================================================
# AZURE BASTION HOST
# =============================================================================

resource "azurerm_public_ip" "publicip" {
  name                = local.publicip_name
  location            = var.location_primary
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
  depends_on = [
    azurerm_subnet.this
  ]
}

resource "azurerm_bastion_host" "bastion" {
  name                = local.bastion_name
  location            = var.location_primary
  resource_group_name = azurerm_resource_group.resourcegroup.name
  tags                = var.common_tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.this["AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.publicip.id
  }
  depends_on = [
    azurerm_subnet.this["AzureBastionSubnet"],
    azurerm_public_ip.publicip
  ]
}
