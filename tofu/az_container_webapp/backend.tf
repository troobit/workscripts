terraform {
  backend "azurerm" {
    resource_group_name  = "rg-iac"
    storage_account_name = "iac"
    container_name       = "tfstate"
    key                  = "this.tfstate"
  }
}
