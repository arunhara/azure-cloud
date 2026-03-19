provider "azurerm" {
  features {}
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
}

module "resource_group" {
  source   = "../../modules/resource-group"
  name     = "rg-${var.org_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}
