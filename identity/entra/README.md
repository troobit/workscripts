# Entra ID: tenant creation and in-tenant configuration

This directory holds the groundwork for a Microsoft Entra ID tenant:

- **This README** — how to create the tenant itself (portal and CLI paths).
- **An OpenTofu root** (`*.tf` in this directory) — users, groups, and
  directory-role assignments, i.e. everything that *is* codifiable once a
  tenant exists.

## Tenant creation is manual and billing-gated

Creating the tenant itself is **not** done by the OpenTofu root here, and it
cannot be fully automated:

- Creating a **workforce tenant** is only supported interactively through the
  Azure portal / Microsoft Entra admin center. There is no Microsoft Graph or
  `az` CLI command for it.
- Creating an **external (CIAM)** or **B2C** tenant programmatically goes
  through an ARM resource provider that must be linked to an active **Azure
  subscription** (billing), and the API requires a *delegated user* token —
  a service principal cannot do it.
- The account that creates a tenant becomes its first **Global
  Administrator**. Licence assignment (Entra ID P1/P2, Intune) is likewise a
  human, billing-gated step.

Plan for a person with billing and global-admin access to perform tenant
creation; everything after that point can be code.

## Portal path (workforce tenant)

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com)
   with an account that has at least the Tenant Creator role in an existing
   tenant (or a brand-new Microsoft account).
2. Browse to **Entra ID > Overview > Manage tenants > Create**.
3. Choose **Workforce** as the tenant type.
4. Provide the organisation name, initial domain name
   (`<name>.onmicrosoft.com`) and country/region — the region cannot be
   changed later.
5. Review and create. You become the tenant's first Global Administrator.

Official documentation:

- [Quickstart: create a new tenant in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/fundamentals/create-new-tenant)
- [Create a Microsoft Entra tenant (identity platform quickstart)](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-create-new-tenant)
- [Create an external tenant (External ID / CIAM)](https://learn.microsoft.com/en-us/entra/external-id/customers/how-to-create-external-tenant-portal)

## CLI path

There is no `az` command that creates a **workforce** tenant — that path is
portal-only. What the CLI *can* do:

### Inspect the tenants you already have

```sh
az login --allow-no-subscriptions
az account tenant list
```

See [`az account tenant`](https://learn.microsoft.com/en-us/cli/azure/account/tenant).

### Create an external (CIAM) tenant via ARM

External ID tenants are exposed as an ARM resource
(`Microsoft.AzureActiveDirectory/ciamDirectories`), so they can be created
with `az rest` against a subscription you own — this is the billing gate:

```sh
az rest --method PUT \
  --url "https://management.azure.com/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.AzureActiveDirectory/ciamDirectories/<TENANT_NAME>?api-version=2023-05-17-preview" \
  --body '{
    "location": "Europe",
    "sku": { "name": "Standard", "tier": "A0" },
    "properties": {
      "createTenantProperties": {
        "displayName": "<DISPLAY_NAME>",
        "countryCode": "IE"
      }
    }
  }'
```

The equivalent exists for legacy B2C tenants
(`Microsoft.AzureActiveDirectory/b2cDirectories`). Note again: the call
requires a signed-in user (delegated token), not a service principal.

Official documentation:

- [CIAM Tenants — Create (REST)](https://learn.microsoft.com/en-us/rest/api/activedirectory/ciam-tenants/create?view=rest-activedirectory-2023-05-17-preview)
- [B2C Tenants — Create (REST)](https://learn.microsoft.com/en-us/rest/api/activedirectory/b2c-tenants/create?view=rest-activedirectory-2021-04-01)
- [`Microsoft.AzureActiveDirectory/ciamDirectories` template reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.azureactivedirectory/ciamdirectories)
- [How to find your tenant ID](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-find-tenant)

## After the tenant exists: the OpenTofu root

Everything inside the tenant that this repo cares about is code, driven by
the `azuread` provider:

| File | Purpose |
| --- | --- |
| `providers.tf` | provider requirements and `azuread` configuration |
| `variables.tf` | data-driven `users` and `groups` variable objects |
| `main.tf` | users, groups, memberships, directory-role assignments |
| `outputs.tf` | object IDs for downstream roots |
| `terraform.tfvars.example` | placeholder example — copy to `terraform.tfvars` |

Role assignments follow the same data-driven `for_each` pattern as the rest
of this repo's OpenTofu: each user or group carries a `role_assignments`
list of `{ role_definition_name, scope }` objects, and the root activates
the referenced directory roles and creates one assignment per entry.

### Usage

```sh
cd identity/entra
cp terraform.tfvars.example terraform.tfvars   # then fill in real values
az login --allow-no-subscriptions --tenant <TENANT_ID>
tofu init
tofu plan
```

No real tenant IDs, object IDs, or domains are committed here — only
placeholders. The root validates offline
(`tofu init -backend=false && tofu validate`); applying it requires the
manual tenant-creation step above to have happened first.

Provider documentation:

- [azuread provider (OpenTofu registry)](https://search.opentofu.org/provider/hashicorp/azuread/latest)
- [azuread provider (Terraform registry docs)](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
