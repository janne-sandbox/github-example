# Azure infrastructure

This Terraform root module provisions the Azure infrastructure used by
`.github/workflows/deploy-azure.yml`:

- one resource group;
- an Azure Container Registry with anonymous access and its admin account disabled;
- an AKS cluster with Microsoft Entra RBAC, local accounts disabled, autoscaling,
  OIDC, workload identity, monitoring, and the managed application-routing add-on;
- explicit control-plane and kubelet managed identities, with narrowly scoped
  `AcrPull` access for the kubelet identity;
- a user-assigned deployment identity trusted only for the configured GitHub
  repository and `production` environment;
- `AcrPush`, AKS credential, and AKS RBAC administrator roles for that deployment
  identity.

Terraform does not create a domain or TLS certificate. After ingress and DNS are
configured, set `FRONTEND_PUBLIC_URL`, `BACKEND_PUBLIC_URL`, and
`BACKEND_PUBLIC_WS_URL` on the GitHub `production` environment.

## Prerequisites

- Terraform 1.10 or newer (the CI example uses 1.15.8)
- an Azure subscription and Microsoft Entra tenant
- Azure credentials allowed to create resource groups, managed identities, role
  assignments, ACR, AKS, and Log Analytics resources
- a GitHub environment named `production`, or a matching
  `github_environment` override

Creating AKS, ACR, public load balancers, and Log Analytics incurs Azure charges.
Review a saved plan before applying it.

## Configure and validate

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Replace the placeholder subscription, tenant, and GitHub repository values.
terraform fmt -check -recursive
terraform init
terraform validate
terraform test
terraform plan -out=github-example.tfplan
terraform show github-example.tfplan
```

Apply only after reviewing the saved plan:

```bash
terraform apply github-example.tfplan
```

The default local state is suitable only for evaluation. For shared or production
use, copy `backend.tf.example` to `backend.tf`, replace its values with an existing
Azure Storage state backend, and run `terraform init -migrate-state`. The state
file can contain infrastructure identifiers and must not be committed.

## Configure GitHub after the first apply

The combined non-secret values expected by the deployment workflow are available
as JSON:

```bash
terraform output -json github_actions_variables
```

Add each returned key/value as a variable on the GitHub `production` environment.
Then add these environment-specific public URLs:

```text
FRONTEND_PUBLIC_URL=https://clock.example.com
BACKEND_PUBLIC_URL=https://api.clock.example.com
BACKEND_PUBLIC_WS_URL=wss://api.clock.example.com
```

The federated credential trusts the exact subject shown by:

```bash
terraform output -raw github_oidc_subject
```

No Azure client secret is created or required.

## Verify Azure after apply

```bash
az acr show --name "$(terraform output -raw acr_name)" --query adminUserEnabled
az aks show \
  --resource-group "$(terraform output -raw resource_group_name)" \
  --name "$(terraform output -raw aks_cluster_name)" \
  --query '{oidc:oidcIssuerProfile.enabled,workloadIdentity:securityProfile.workloadIdentity.enabled}'
az role assignment list \
  --scope "$(az acr show --name "$(terraform output -raw acr_name)" --query id -o tsv)" \
  --output table
```

Finally, dispatch `deploy-azure.yml`, verify both Kubernetes rollouts, and inspect
the public HTTPS/WSS endpoints. Local `terraform validate` or mocked tests do not
prove that Azure provisioning or the hosted rollout succeeded.
