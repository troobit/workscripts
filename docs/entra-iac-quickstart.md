# Quickstart: Entra ID as code (OpenTofu)

Pointers only — the work is already done in this repo. Each link is the
authoritative doc for its step; nothing is duplicated here.

## 1. Create the tenant (manual, billing-gated)

Tenant creation cannot be codified — a human with billing and global-admin
access does it once. Portal and CLI paths, with Microsoft Learn links:

- [`identity/entra/README.md`](../identity/entra/README.md) — "Tenant creation
  is manual and billing-gated", portal path, CLI path.

## 2. Codify users, groups, and directory roles

An OpenTofu root using the `azuread` provider, data-driven via
`terraform.tfvars` (placeholders only committed):

- [`identity/entra/`](../identity/entra/README.md) — root layout, usage
  (`tofu init` / `plan`), and provider doc links.
- [`identity/README.md`](../identity/README.md) — how the area fits together
  and repo-wide OpenTofu conventions.
- [`tofu/README.md`](../tofu/README.md) — the wider collection of OpenTofu
  roots, quality gates, and comment conventions.

## 3. Deploy from one machine (working state)

The "Usage" section of [`identity/entra/README.md`](../identity/entra/README.md):
`az login --allow-no-subscriptions --tenant <TENANT_ID>`, copy the
`terraform.tfvars.example`, then `tofu init` / `tofu plan`.

## 4. Deploy via GitHub with OIDC (target state)

Workflow templates and the auth model (user-assigned managed identity,
federated credential, no client secrets, state-storage firewall open/close):

- [`azure/README.md`](../azure/README.md) — "Auth model: OIDC with a
  user-assigned managed identity" and the greenfield setup steps.
- [`azure/github-workflows/tf-deploy.yml`](../azure/github-workflows/tf-deploy.yml)
  — the IaC plan/apply/destroy template. Template for *other* repos: copy it
  into the target repo's `.github/workflows/`; it must not run here.

## Not yet codified

- **Conditional access / user policies** — the Entra root manages users,
  groups, and directory-role assignments; conditional access policies are not
  templated yet. When needed, add them to `identity/entra/` with the provider's
  [`azuread_conditional_access_policy`](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/conditional_access_policy)
  resource.
- **Tenant creation and licensing** — permanently manual (see step 1).
