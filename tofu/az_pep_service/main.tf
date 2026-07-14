# =============================================================================
# Variables
# =============================================================================

variable "endpointsvc_rg_name" {
  default = "endpointsvc-rg"
}

# =============================================================================
# Create RG
# =============================================================================

resource "azurerm_resource_group" "endpointsvc_rg" {
  name     = var.endpointsvc_rg_name
  location = var.location
  tags     = merge(var.common_tags, { "ResourceType" = "Resource Group" }, { "ResourceName" = var.endpointsvc_rg_name })
}