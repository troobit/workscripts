# windows/

General Windows notes that are not PowerShell scripts.

## Layout

```
windows/
└── general-win-use.txt   # registry tweaks and Explorer/Outlook settings notes
```

## Conventions

- Plain-text or markdown notes only; anything executable belongs in [powershell/](../powershell/README.md).
- `general-win-use.txt` collects registry locations (BitLocker write access, Outlook attachment types) and `HKCU` Explorer `Advanced` values, phrased for use via `Get-PSDrive`/registry-as-filesystem in PowerShell.
- Windows Autopilot groundwork lives in [identity/](../identity/README.md), not here.
