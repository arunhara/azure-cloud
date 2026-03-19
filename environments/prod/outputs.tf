output "resource_group_id" {
  description = "Resource group ID"
  value       = module.resource_group.id
}

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.name
}

output "environment" {
  description = "Environment (prod)"
  value       = var.environment
}
