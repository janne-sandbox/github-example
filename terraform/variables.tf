variable "subscription_id" {
  description = "Azure subscription in which the example infrastructure is created."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be an Azure subscription UUID."
  }
}

variable "tenant_id" {
  description = "Microsoft Entra tenant used by Azure and GitHub OIDC."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.tenant_id))
    error_message = "tenant_id must be a Microsoft Entra tenant UUID."
  }
}

variable "github_repository" {
  description = "GitHub repository in owner/name form allowed to deploy through OIDC."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must use owner/name format."
  }
}

variable "github_environment" {
  description = "GitHub environment whose jobs may exchange an OIDC token."
  type        = string
  default     = "production"

  validation {
    condition     = length(trimspace(var.github_environment)) > 0
    error_message = "github_environment must not be empty."
  }
}

variable "project_name" {
  description = "Short name used as the prefix for Azure resources."
  type        = string
  default     = "github-example"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.project_name))
    error_message = "project_name must be 3-31 lowercase letters, numbers, or hyphens and start with a letter."
  }
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "prod"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,10}$", var.environment))
    error_message = "environment must be 2-11 lowercase letters, numbers, or hyphens and start with a letter."
  }
}

variable "location" {
  description = "Azure region for all regional resources."
  type        = string
  default     = "North Europe"
}

variable "resource_group_name" {
  description = "Optional resource group name; generated from project and environment when null."
  type        = string
  default     = null
  nullable    = true
}

variable "acr_name" {
  description = "Optional globally unique ACR name; a suffix is generated when null."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.acr_name == null || can(regex("^[a-zA-Z0-9]{5,50}$", var.acr_name))
    error_message = "acr_name must contain 5-50 alphanumeric characters."
  }
}

variable "acr_sku" {
  description = "Azure Container Registry service tier."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "acr_sku must be Basic, Standard, or Premium."
  }
}

variable "aks_cluster_name" {
  description = "Optional AKS cluster name; generated when null."
  type        = string
  default     = null
  nullable    = true
}

variable "kubernetes_version" {
  description = "Optional AKS Kubernetes version. Null selects Azure's current default."
  type        = string
  default     = null
  nullable    = true
}

variable "system_node_vm_size" {
  description = "VM SKU for the AKS system node pool."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "system_node_count" {
  description = "Initial AKS system node count."
  type        = number
  default     = 1

  validation {
    condition     = var.system_node_count >= 1 && var.system_node_count <= 10
    error_message = "system_node_count must be between 1 and 10."
  }
}

variable "system_node_min_count" {
  description = "Minimum AKS system node count."
  type        = number
  default     = 1

  validation {
    condition     = var.system_node_min_count >= 1 && var.system_node_min_count <= 10
    error_message = "system_node_min_count must be between 1 and 10."
  }
}

variable "system_node_max_count" {
  description = "Maximum AKS system node count."
  type        = number
  default     = 3

  validation {
    condition     = var.system_node_max_count >= 1 && var.system_node_max_count <= 20
    error_message = "system_node_max_count must be between 1 and 20."
  }
}

variable "enable_monitoring" {
  description = "Create Log Analytics and enable the AKS monitoring agent."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags merged with the project and environment tags."
  type        = map(string)
  default     = {}
}
