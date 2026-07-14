# identity/

Groundwork for identity and device management: Microsoft Entra ID and
Windows Autopilot. Everything here is documentation plus validating
config-as-code — **nothing is applied against a real tenant**. Creating a
tenant, assigning licences, and enrolling devices are human, billing-gated
steps (see the STOP notes in each area).

## Layout

| Path | Contents |
| --- | --- |
| [`entra/`](entra/README.md) | Tenant creation docs (portal + CLI) and an OpenTofu root (`azuread` provider) for users, groups, and directory-role assignments |
| [`autopilot/`](autopilot/README.md) | The Windows Autopilot moving parts, each linked to official Microsoft Learn docs, plus a Graph API config-as-code skeleton (scaffolding) |

## Conventions

- OpenTofu is the toolchain (`tf` aliased to `tofu` locally); roots validate
  offline with `tofu init -backend=false && tofu validate`.
- `.tf` files use the repo-wide 77-character `# ===` banner comments with
  terse lowercase inline rationale.
- No real tenant IDs, object IDs, or domains are committed — placeholders
  only, with `*.example` files to copy from.

## Related PowerShell scripts

Earlier scripts in this repo touch the same ground from the on-premises and
Azure sides. They stay where they are — referenced here, not moved.

> **Note on paths**: the repo restructure (sibling branch) renames
> `PowerShell/` to `powershell/` with space-free subdirectory names. The
> links below use those **future** paths and will only resolve once that
> branch is merged; `lychee --offline` failures against them are expected
> until then.

- [`powershell/active-directory/`](../powershell/active-directory/) —
  on-prem Active Directory group auditing (AD group delta and membership
  checks), the directory predecessor of the Entra work in `entra/`.
- [`powershell/azure/`](../powershell/azure/) — Azure scripts (VM
  deployment, Key Vault secrets, subscription cleanup) that assume the
  tenant and RBAC groundwork this area codifies.
