terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.27.0"
    }
  }
  # backend values are environment-specific and supplied at init time:
  #   tofu init -backend-config=environments/dev-backend.hcl
  backend "azurerm" {}
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
