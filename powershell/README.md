# powershell/

PowerShell scripts for Windows administration and Azure work.

## Layout

```
powershell/
├── *.ps1                   # standalone utility scripts (hashing, PDF, Teams, Splunk, ...)
├── active-directory/       # AD group auditing and delta reporting
├── azure/                  # Az module scripts: VMs, Key Vault, subscription cleanup
├── ms-samples/             # Microsoft sample scripts (AzureRM-era VM/VPN/DC deployment)
├── ps-month-of-lunches/    # exercises from "Learn PowerShell in a Month of Lunches"
└── ps-profiles/            # PowerShell and VS Code profile files
```

## Conventions

- Standalone one-off utilities live at the top level; anything with a shared theme gets a subdirectory.
- Subdirectory names are lowercase kebab-case (no spaces). Script file names keep their original casing.
- Scripts are self-contained — no shared module; each declares or comments its own prerequisites (e.g. `Az` module, RSAT/AD module, Word COM).
- `ms-samples/` is reference material copied from Microsoft docs and kept as-is; it predates the Az module (uses AzureRM cmdlets) and is not maintained.
- Related identity/RBAC config-as-code lives in [identity/](../identity/README.md); OpenTofu infrastructure lives in [tofu/](../tofu/README.md).
