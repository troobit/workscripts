# =============================================================================
# Defining Provider Data
# =============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
  # backend values are environment-specific and supplied at init time:
  #   tofu init -backend-config=environments/dev-backend.hcl
  backend "azurerm" {}
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}
