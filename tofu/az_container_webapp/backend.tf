terraform {
  # backend values are environment-specific and supplied at init time:
  #   tofu init -backend-config=environments/dev-backend.hcl
  backend "azurerm" {}
}
