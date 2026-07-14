# ====================================================================================
# Private Link
# ====================================================================================

resource "azurerm_private_endpoint" "privateendpoint" {
  name                = "pvtendpoint-${var.plinkname}"
  location            = var.location
  resource_group_name = var.rgname
  subnet_id           = var.subnetid
  tags                = var.tags

  private_service_connection {
    name                              = "pvtserviceconnection-${var.plinkname}"
    private_connection_resource_alias = var.serviceendpointresourcealias
    is_manual_connection              = true
    request_message                   = var.requestmessage
  }
}

#  For creating based on whether "value" is true or false - good trick for modules with different options.
#  count = var.type == "value" ? 1 : 0