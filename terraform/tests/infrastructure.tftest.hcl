mock_provider "azurerm" {
  mock_resource "azurerm_kubernetes_cluster" {
    defaults = {
      oidc_issuer_url = "https://mock.oic.prod-aks.azure.com/tenant/cluster/"
    }
  }
}
mock_provider "random" {
  mock_resource "random_string" {
    defaults = {
      result = "a1b2c3d4"
    }
  }
}

run "secure_default_plan" {
  command = plan

  variables {
    subscription_id   = "11111111-1111-1111-1111-111111111111"
    tenant_id         = "22222222-2222-2222-2222-222222222222"
    github_repository = "example/github-example"
  }

  assert {
    condition     = azurerm_container_registry.main.admin_enabled == false
    error_message = "The ACR admin account must remain disabled."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.local_account_disabled
    error_message = "AKS local accounts must remain disabled."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.oidc_issuer_enabled && azurerm_kubernetes_cluster.main.workload_identity_enabled
    error_message = "AKS OIDC and workload identity must remain enabled."
  }

  assert {
    condition     = azurerm_federated_identity_credential.github_actions.subject == "repo:example/github-example:environment:production"
    error_message = "GitHub federation must be scoped to the configured repository environment."
  }

  assert {
    condition     = azurerm_role_assignment.aks_acr_pull.role_definition_name == "AcrPull"
    error_message = "AKS image pull access must use the AcrPull role."
  }
}
