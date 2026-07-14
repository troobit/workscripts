module "privatelink-01" {
  source         = "./modules/private-link-endpoint"
  plinkname      = "privateLink01"
  requestmessage = "Send This Request Message"
  # the private link service lives in the az_pep_service root; pass its alias output in via tfvars
  serviceendpointresourcealias = var.private_link_service_alias
  rgname                       = azurerm_resource_group.ingress_rg.name
  location                     = var.location
  subnetid                     = azurerm_subnet.privatelinks.id
  tags                         = merge(var.common_tags, { "PLinkConnection" = "Dev1" }, { "AnotherTag" = "Tag2" })
}