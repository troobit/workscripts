module "privatelink-01" {
  source = "./modules/private-link-endpoint"
  plinkname = "privateLink01"
  requestmessage = "Send This Request Message"
  serviceendpointresourcealias = azurerm_private_link_service.plink_service.alias
  rgname = azurerm_resource_group.ingress_rg.name
  location = var.location
  subnetid = azurerm_subnet.privatelinks.id
  tags = merge(var.common_tags, {"PLinkConnection" = "Dev1"}, {"AnotherTag" = "Tag2"})
}