# tofu/

Independent OpenTofu roots migrated from the standalone `~/Downloads/tf` collection.
Each directory is a self-contained root (own state, own providers); `modules/`
subdirectories hold local modules used only by their root. The local toolchain is
OpenTofu — `tf` is aliased to `tofu`.

## Layout

```
tofu/
├── aws/
│   ├── simple_ec2/          # VPC via the registry terraform-aws-modules/vpc module
│   └── vpc/                 # hand-rolled multi-account VPC, YAML-driven subnets
├── az_container_webapp/     # Container App + Key Vault + vnet, OIDC auth
│   └── modules/
│       ├── containerapp/    # container app with KV-backed secrets
│       ├── umid/            # user-assigned managed identity + role assignments
│       └── vnet/            # vnet, subnets, NSGs
├── az_monitoring/           # Log Analytics workspace + linked storage account
├── az_pep_service/          # Private Link service behind an internal LB + web VMs
├── az_private_endpoints/    # consumer side: vnet, bastion, private endpoints
│   └── modules/
│       └── private-link-endpoint/
├── az_vnet/                 # vnets/subnets from config/networks.yml
│   ├── delegation/          # subnet delegation + bastion variant
│   └── peering/             # hub/spoke peering variant (YAML-driven)
│       └── ignore/          # pre-YAML hand-written reference files (inert)
└── az_webserver/            # single marketplace nginx VM with public IP
```

Not migrated: `az_test_workloads` (empty in the source, dropped) and
`az_hostedrunner` (Docker, not IaC — it lives under `azure/hosted-runner/`).
`az_container_webapp` had a redundant `terraform/` wrapper directory in the
source; the root was flattened one level.

## Quality gates

Every root passes, offline:

```sh
tofu fmt -check
tofu init -backend=false && tofu validate
```

## Comment convention

Section banners are the 77-character `# ===` form (older roots used an 84-character
variant and were normalised):

```hcl
# =============================================================================
# Container App Environment
# =============================================================================
```

Terse lowercase inline rationale comments and intentionally commented-out
reference blocks (e.g. the removed KV role assignment in
`az_container_webapp/keyvault.tf`) are part of the style — keep them.

## Backend and tfvars pattern

No real storage-account names, subscription IDs, tenant IDs, or role ARNs live in
`.tf` files. Two mechanisms:

- **Backends** — roots with remote state declare an empty `backend "azurerm" {}`
  and take their config from per-environment files at init time:

  ```sh
  cp environments/dev-backend.hcl.example environments/dev-backend.hcl
  # fill in real values, then
  tofu init -backend-config=environments/dev-backend.hcl
  ```

  The `*.example` files are committed; real `*-backend.hcl` files are gitignored.

- **Variables** — environment-specific values (subscription/tenant IDs, AWS
  profiles, role ARNs) are declared without defaults. Each root commits an
  `example.tfvars`; copy it to `<name>.auto.tfvars` (auto-loaded, gitignored)
  and fill in real values.

## YAML-driven network config

`az_vnet`, `az_vnet/peering`, and `aws/vpc` define their networks declaratively in
`config/networks.yml` rather than in HCL. The pattern:

1. `yamldecode(file("./config/networks.yml"))` loads the structure into a local.
2. Nested `for` comprehensions with `flatten` turn the vnet→subnet (or
   vpc→az→subnet) hierarchy into flat lists of objects.
3. Resources iterate with `for_each = { for k, v in local.x : v.name => v }`
   (a map, keyed by name, so plans stay stable when the list order changes).

Adding a subnet is a YAML edit, not a resource edit. See
`az_vnet/vnets.tf` and `aws/vpc/vpc.tf` for the canonical implementations.

## Disabled-file decisions

Files disabled in the source (`.tf.ignore` suffix or `ignore/` directories) were
carried or dropped as follows. Carried reference files are inert (not loaded by
`tofu`) and were intentionally left unchanged — banners and naming inside them are
as found:

| Source file | Decision |
| --- | --- |
| `az_private_endpoints/05_nsg.tf.ignore` | carried as `nsg.tf.ignore` — NSG reference; refers to `ws_*` resources that no longer exist in the root |
| `az_private_endpoints/07_jumphost.tf.ignore` | carried as `jumphost.tf.ignore` — Windows jump host reference; its `jh_count` variable is now also declared in `variables.tf` because the active `ingress_vnet.tf` uses it |
| `az_vnet/peering/ignore/03_network_hub.tf` | carried as `ignore/network_hub.tf` — pre-YAML hand-written hub vnet |
| `az_vnet/peering/ignore/03_network_hub_bastionhost.tf` | carried as `ignore/network_hub_bastionhost.tf` — bastion for the hand-written hub |
| `az_vnet/peering/ignore/03_network_peerings.tf` | carried as `ignore/network_peerings.tf` — explicit two-way peering pair |
| `az_vnet/peering/ignore/03_network_spoke_1.tf` | carried as `ignore/network_spoke_1.tf` — hand-written spoke vnet |
| `az_vnet/peering/ignore/04_LinuxServers.tf` | carried as `ignore/linux_servers.tf` — test VMs for the peered vnets |

Also dropped during migration (not `.tf.ignore`, but recorded for completeness):
empty placeholder files (`aws/vpc/natgw.tf`, `az_monitoring/04_Roles.tf`,
`az_private_endpoints/modules/private-link-endpoint/outputs.tf`), the personal
`envauth-local.sh` (real key vault name; the templated `envauth.sh` / `envauth.ps1`
were kept), per-root `.gitignore` files (superseded by `tofu/.gitignore`), and all
`.terraform.lock.hcl` / state files.

## Notable migration fixes

Renames: the numbered `00_Providers.tf` / `01_Variables.tf` scheme in the older
roots was replaced with the conventional `main.tf` / `variables.tf` /
`outputs.tf` / `providers.tf` plus per-feature files (`network.tf`,
`webservers.tf`, …).

Fixes needed to reach a clean `tofu validate`:

- `aws/simple_ec2` — provider referenced undeclared `var.profile`; now
  `var.aws_profile`.
- `az_pep_service` — `endpointsvc_count` was referenced but never declared;
  declared with a default of 2 (matching `app_server_count`).
- `az_private_endpoints` — `jh_count` declared in the root (its only
  declaration was inside the disabled jump host file); the private link
  service alias, which pointed at a resource living in the separate
  `az_pep_service` root, is now `var.private_link_service_alias`; the module's
  unused `privateIP` variable gained a default so callers need not pass it.
- `az_vnet/delegation` — resources referenced `azurerm_resource_group.resourcegroup`
  but the resource is named `rg`; references fixed. A stray tab inside the unused
  `vnet_cidr` local's CIDR string was trimmed.
- `az_monitoring` — provider constraint `>=2.93.1` floated to azurerm 4.x, so it
  is now pinned `~> 4.0`; the retired `Free` Log Analytics sku became `PerGB2018`.
- `az_webserver` — had no `required_providers` at all; pinned azurerm `~> 3.116`
  (matching the era of its syntax) and tls. NSG rule protocol `TCP` corrected to
  `Tcp` (case-sensitive in the provider).
- IaC-marker tag keys/values were renamed to `OpenTofu` across the roots.
- Provider source addresses, `required_providers` sources, and the registry
  module source in `aws/simple_ec2` are unchanged.
