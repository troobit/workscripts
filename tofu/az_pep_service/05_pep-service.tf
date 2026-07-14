variable "plink_ip_address" {
  default = "10.1.0.8"
}

resource "azurerm_private_link_service" "plink_service" {
  name                = "endpointsvc-privatelink-svc"
  resource_group_name = azurerm_resource_group.endpointsvc_rg.name
  location            = var.location

  auto_approval_subscription_ids              = var.auto_approval_subscription_ids
  visibility_subscription_ids                 = var.visibility_subscription_ids
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.lb.frontend_ip_configuration.0.id]

  nat_ip_configuration {
    name                       = "primary"
    private_ip_address         = var.plink_ip_address
    private_ip_address_version = "IPv4"
    subnet_id                  = azurerm_subnet.endpointsvc_default_sn.id
    primary                    = true
  }

  depends_on = [
    azurerm_subnet.endpointsvc_default_sn
  ]
}

output "endpoint_svc_resource_alias" {
  value = azurerm_private_link_service.plink_service.alias
}