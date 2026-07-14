# ====================================================================================
# Bastion Host
# ====================================================================================

resource "azurerm_public_ip" "bastion" {
  name                = "bastion-pip"
  resource_group_name = var.rg_name
  location            = var.location_primary
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
  depends_on = [
    azurerm_resource_group.rg,
  azurerm_virtual_network.hub-vnet]
}

resource "azurerm_bastion_host" "bastion" {
  name                = "dev-bastion"
  location            = var.location_primary
  resource_group_name = var.rg_name
  tags                = var.common_tags

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
  depends_on = [
    azurerm_subnet.bastion,
    azurerm_virtual_network.hub-vnet,
    azurerm_public_ip.bastion
  ]
}

# ====================================================================================
# NSGs and Associations
# ====================================================================================

resource "azurerm_network_security_group" "hub_nsg" {
  name                = "hub-nsg"
  location            = var.location_primary
  resource_group_name = var.rg_name
  security_rule {
    name                       = "allow-inbound-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-inbound-gw-manager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-inbound-loadbalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-inbound-bastion-host-comms"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-outbound-ssh-rdp"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "allow-outbound-azure"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
  security_rule {
    name                       = "allow-outbound-bastion-host-comms"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "allow-outbound-http"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.rg, azurerm_subnet.bastion]
}

resource "azurerm_subnet_network_security_group_association" "bastion-nsg-assoc" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.hub_nsg.id
  depends_on                = [azurerm_network_security_group.hub_nsg]
}
