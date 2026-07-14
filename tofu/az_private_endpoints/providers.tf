terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.27.0"
    }
  }
  backend "azurerm" {
      resource_group_name               = "terraform"
      storage_account_name              = "tfrtobsa"
      container_name                    = "tfstate"
      key                               = "privatelinks.tf.state"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}