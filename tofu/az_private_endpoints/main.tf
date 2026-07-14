# =============================================================================
# Variables
# =============================================================================

variable "ingress_rg_name" {
  default = "pl-rg"
}

# =============================================================================
# Create RG
# =============================================================================

resource "azurerm_resource_group" "ingress_rg" {
    name                                = var.ingress_rg_name
    location                            = var.location
    tags                                = merge(var.common_tags, {"ResourceType" = "Resource Group"}, {"ResourceName" = var.ingress_rg_name})
}