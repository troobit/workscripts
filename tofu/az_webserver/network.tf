# =============================================================================
# Variables
# =============================================================================

variable "vnet_name" {
  default = "vnet_name"
}

variable "vnet_CIDR" {
  default = ["10.0.0.0/16"]
}

variable "subnet1_CIDR" {
  default = ["10.0.0.0/24"]
}

variable "private_ip" {
  default = "10.0.0.10"
}
# =============================================================================
# VNETs (and subnets)
# =============================================================================

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = var.vnet_CIDR
  tags                = merge(var.common_tags, { "Resource Type" = "vnet" })

  depends_on = [azurerm_resource_group.rg]
}



resource "azurerm_subnet" "subnet" {
  name                 = "sn01"
  address_prefixes     = var.subnet1_CIDR
  virtual_network_name = var.vnet_name
  resource_group_name  = var.rg_name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# =============================================================================
# NSGs and Associations
# =============================================================================

resource "azurerm_network_security_group" "nsg" {
  name                = "ws-nsg"
  location            = var.location
  resource_group_name = var.rg_name

  security_rule {
    name                       = "ssh-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "http-inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "https-inbound"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.rg, azurerm_subnet.subnet]
}

resource "azurerm_subnet_network_security_group_association" "nsg-assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on                = [azurerm_network_security_group.nsg]
}

# =============================================================================
# PIPs
# =============================================================================

resource "azurerm_public_ip" "pip" {
  name                = "ws-pip"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = "Dynamic"
  tags                = var.common_tags
  depends_on = [
    azurerm_resource_group.rg,
  azurerm_virtual_network.vnet]
}

# =============================================================================
# NICs
# =============================================================================

resource "azurerm_network_interface" "nic" {
  name                = "ws-nic"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "ws-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = var.private_ip
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "pip" {
  value = azurerm_public_ip.pip.ip_address
}