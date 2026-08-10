resource "random_string" "acr_suffix" {
  length  = 8
  upper   = false
  special = false

  keepers = {
    environment  = var.environment
    project_name = var.project_name
  }
}

locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  resource_group     = coalesce(var.resource_group_name, "rg-${local.name_prefix}")
  aks_cluster_name   = coalesce(var.aks_cluster_name, "aks-${local.name_prefix}")
  acr_project_prefix = replace(lower(var.project_name), "/[^a-z0-9]/", "")
  acr_name           = coalesce(var.acr_name, substr("${local.acr_project_prefix}${var.environment}${random_string.acr_suffix.result}", 0, 50))
  common_tags = merge({
    application = var.project_name
    environment = var.environment
    managed-by  = "terraform"
  }, var.tags)
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_container_registry" "main" {
  name                          = local.acr_name
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  sku                           = var.acr_sku
  admin_enabled                 = false
  public_network_access_enabled = true
  anonymous_pull_enabled        = false
  role_assignment_mode          = "LegacyRegistryPermissions"
  tags                          = local.common_tags
}

resource "azurerm_log_analytics_workspace" "main" {
  count = var.enable_monitoring ? 1 : 0

  name                = "log-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "aks_control_plane" {
  name                = "id-${local.name_prefix}-aks-control-plane"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "aks_kubelet" {
  name                = "id-${local.name_prefix}-aks-kubelet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "aks_control_plane_kubelet_operator" {
  scope                            = azurerm_user_assigned_identity.aks_kubelet.id
  role_definition_name             = "Managed Identity Operator"
  principal_id                     = azurerm_user_assigned_identity.aks_control_plane.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.aks_cluster_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dns_prefix          = local.aks_cluster_name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"

  local_account_disabled       = true
  oidc_issuer_enabled          = true
  workload_identity_enabled    = true
  automatic_upgrade_channel    = "patch"
  node_os_upgrade_channel      = "NodeImage"
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 168

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    node_count                   = var.system_node_count
    auto_scaling_enabled         = true
    min_count                    = var.system_node_min_count
    max_count                    = var.system_node_max_count
    only_critical_addons_enabled = true
    os_disk_type                 = "Managed"
    os_disk_size_gb              = 64
    type                         = "VirtualMachineScaleSets"
    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_control_plane.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.aks_kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.aks_kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.aks_kubelet.id
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = var.tenant_id
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
    service_cidr        = "10.2.0.0/24"
    dns_service_ip      = "10.2.0.10"
  }

  web_app_routing {
    dns_zone_ids             = []
    default_nginx_controller = "External"
  }

  dynamic "oms_agent" {
    for_each = var.enable_monitoring ? [1] : []
    content {
      log_analytics_workspace_id      = azurerm_log_analytics_workspace.main[0].id
      msi_auth_for_monitoring_enabled = true
    }
  }

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.aks_control_plane_kubelet_operator]

  lifecycle {
    precondition {
      condition = (
        var.system_node_min_count <= var.system_node_count &&
        var.system_node_count <= var.system_node_max_count
      )
      error_message = "system_node_count must be between system_node_min_count and system_node_max_count."
    }
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_user_assigned_identity.aks_kubelet.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_user_assigned_identity" "github_actions" {
  name                = "id-${local.name_prefix}-github"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

resource "azurerm_federated_identity_credential" "github_actions" {
  name      = "github-${var.github_environment}"
  parent_id = azurerm_user_assigned_identity.github_actions.id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${var.github_repository}:environment:${var.github_environment}"
}

resource "azurerm_role_assignment" "github_acr_push" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPush"
  principal_id                     = azurerm_user_assigned_identity.github_actions.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "github_aks_user" {
  scope                            = azurerm_kubernetes_cluster.main.id
  role_definition_name             = "Azure Kubernetes Service Cluster User Role"
  principal_id                     = azurerm_user_assigned_identity.github_actions.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "github_aks_rbac_admin" {
  scope                            = azurerm_kubernetes_cluster.main.id
  role_definition_name             = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id                     = azurerm_user_assigned_identity.github_actions.principal_id
  skip_service_principal_aad_check = true
}
