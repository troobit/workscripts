# =============================================================================
# Variables
# =============================================================================

variable "frontend_ipconfig_name" {
  default = "lb-frontend-ipconfig"
}

# =============================================================================
# LB and Rules
# =============================================================================

resource "azurerm_lb" "lb" {
  name                = "endpointsvc-lb"
  sku                 = "Standard"
  location            = var.location
  resource_group_name = azurerm_resource_group.endpointsvc_rg.name

  frontend_ip_configuration {
    name                          = var.frontend_ipconfig_name
    subnet_id                     = azurerm_subnet.endpointsvc_default_sn.id
    private_ip_address_allocation = "Dynamic"
  }
}

#how to filter incoming requests - 
resource "azurerm_lb_rule" "lb_rule_http" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "lb-rule-http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = var.frontend_ipconfig_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend.id]
  depends_on = [
    azurerm_lb_backend_address_pool.lb_backend
  ]
}

# =============================================================================
# Backend and Associations
# =============================================================================

resource "azurerm_lb_backend_address_pool" "lb_backend" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "endpointsvc_lb_backend_assoc" {
  count                = var.endpointsvc_count
  network_interface_id = azurerm_network_interface.endpointvm_nic[count.index].id
  #ip config name is defined ON THE SOURCE VNIC
  ip_configuration_name   = "endpointsvc-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend.id
}