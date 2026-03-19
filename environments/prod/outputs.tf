output "resource_group_id" {
  description = "Resource group ID"
  value       = module.resource_group.id
}

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.name
}

output "vnet_name" {
  description = "Virtual network name"
  value       = module.network.vnet_name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID"
  value       = module.network.subnet_ids
}

output "environment" {
  description = "Environment (prod)"
  value       = var.environment
}
