# State address rename only (Terraform >= 1.1). Does not change Azure resources.
# Older revisions used the local name "subnet" for NSG and association blocks; those
# were renamed to "nsg" and "subnet_nsg" for clarity. If your state still has the old
# addresses, the blocks below rebind them in one plan/apply. New workspaces no-op.
# You may delete this file after every environment has applied successfully once with
# the new names (optional cleanup).

moved {
  from = azurerm_network_security_group.subnet
  to   = azurerm_network_security_group.nsg
}

moved {
  from = azurerm_subnet_network_security_group_association.subnet
  to   = azurerm_subnet_network_security_group_association.subnet_nsg
}
