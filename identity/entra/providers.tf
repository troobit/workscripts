# =============================================================================
# Providers
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azuread" {
  # tenant creation is manual (see README.md); this root only configures an
  # existing tenant, so the id always arrives as input
  tenant_id = var.tenant_id
}
