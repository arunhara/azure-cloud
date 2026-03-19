variable "name" {
  description = "Name of the virtual network"
  type        = string
}

variable "location" {
  description = "Azure region for the virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group that hosts the network"
  type        = string
}

variable "address_space" {
  description = "Address spaces for the virtual network"
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "Map of subnet name => CIDR prefix"
  type        = map(string)
}

variable "tags" {
  description = "Tags to apply to the virtual network"
  type        = map(string)
  default     = {}
}
