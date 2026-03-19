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

module "network" {
  source              = "../../modules/network"
  name                = "vnet-${var.org_name}-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = var.vnet_address_space
  subnet_prefixes     = var.subnet_prefixes
  tags                = var.tags
}
