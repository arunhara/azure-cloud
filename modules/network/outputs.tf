output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.vnet.name
}

output "subnet_ids" {
  description = "Map of subnet name => subnet ID"
  value       = { for name, subnet in azurerm_subnet.subnet : name => subnet.id }
}

output "nsg_ids" {
  description = "Map of subnet name => NSG ID (one NSG per subnet)"
  value       = { for name, nsg in azurerm_network_security_group.nsg : name => nsg.id }
}
