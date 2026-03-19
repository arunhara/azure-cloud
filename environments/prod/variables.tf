variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID (optional)"
  type        = string
  default     = ""
}

variable "org_name" {
  description = "Organization prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Short project identifier"
  type        = string
  default     = "azure-cloud"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
