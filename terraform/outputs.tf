output "resource_group_name" {
  description = "Resource group containing the application infrastructure."
  value       = azurerm_resource_group.main.name
}

output "acr_name" {
  description = "Azure Container Registry name."
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Azure Container Registry login server used in image references."
  value       = azurerm_container_registry.main.login_server
}

output "aks_cluster_name" {
  description = "Azure Kubernetes Service cluster name."
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer exposed by AKS for workload identities."
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "github_actions_client_id" {
  description = "Client ID for the AZURE_CLIENT_ID GitHub variable."
  value       = azurerm_user_assigned_identity.github_actions.client_id
}

output "github_actions_variables" {
  description = "Non-secret values to configure on the GitHub production environment."
  value = {
    ACR_NAME              = azurerm_container_registry.main.name
    AKS_CLUSTER_NAME      = azurerm_kubernetes_cluster.main.name
    AKS_RESOURCE_GROUP    = azurerm_resource_group.main.name
    AZURE_CLIENT_ID       = azurerm_user_assigned_identity.github_actions.client_id
    AZURE_SUBSCRIPTION_ID = var.subscription_id
    AZURE_TENANT_ID       = var.tenant_id
  }
}

output "github_oidc_subject" {
  description = "Exact GitHub OIDC subject trusted by the deployment identity."
  value       = azurerm_federated_identity_credential.github_actions.subject
}
