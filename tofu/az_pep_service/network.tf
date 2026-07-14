# =============================================================================
# This section goes through creating the vnet and nics for the private link services.
# =============================================================================

# =============================================================================
# Variables
# =============================================================================

variable "endpointsvc_vnet_name" {
  default = "endpointsvc-vnet"  
}

variable "endpointsvc_vnet_CIDR" {
  default = ["10.1.0.0/16"]
}

variable "frontend_CIDR" {
  default = ["10.1.0.0/24"]
}

variable "endpointsvc_default_subnet_name" {
  default = "endpointsvc-default-sn"
}

# =============================================================================
# VNETs (and subnets)
# =============================================================================

resource "azurerm_virtual_network" "endpointsvc_vnet" {
  name                = var.endpointsvc_vnet_name
  location            = var.location
  resource_group_name = var.endpointsvc_rg_name
  address_space       = ["10.1.0.0/16"]
  tags = merge(var.common_tags, {"Resource Type" = "vnet"})
  depends_on = [azurerm_resource_group.endpointsvc_rg]
}

resource "azurerm_subnet" "endpointsvc_default_sn" {
  name           = var.endpointsvc_default_subnet_name
  address_prefixes = var.frontend_CIDR
  private_link_service_network_policies_enabled = false
  virtual_network_name = var.endpointsvc_vnet_name
  resource_group_name = var.endpointsvc_rg_name
  depends_on = [
    azurerm_virtual_network.endpointsvc_vnet
  ]
}

# =============================================================================
# NICs
# =============================================================================

resource "azurerm_network_interface" "endpointvm_nic" {
  count = var.endpointsvc_count
  name                           = "endpoint-vm-nic-${format("%02d", count.index + 1)}"
  location                       = var.location
  resource_group_name            = var.endpointsvc_rg_name

  ip_configuration {
    name                         = "endpointsvc-ipconfig"
    subnet_id                    = azurerm_subnet.endpointsvc_default_sn.id
    private_ip_address_allocation = "Dynamic"
    #private_ip_address           = var.private_ip
    #public_ip_address_id         = azurerm_public_ip.pip.id
  }
}