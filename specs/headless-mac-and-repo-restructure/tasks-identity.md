---
references:
    - prd.md
---
# Headless Mac setup and repo restructure — identity

## Entra ID

- [ ] 1. Write identity/entra/README.md: tenant creation docs (portal + CLI) with official Microsoft links <!-- id:8frf0u2 -->
  - Explicit that tenant creation is a manual, billing-gated step
  - Stream: 1

- [ ] 2. Build identity/entra/ OpenTofu root with azuread provider: users, groups, role assignments <!-- id:8frf0u3 -->
  - Data-driven for_each role-assignment pattern from sanarte umid module
  - Repo banner-comment style (77-char # === banners)
  - Passes tofu fmt -check and tofu init -backend=false + tofu validate
  - Stream: 1

## Autopilot

- [ ] 3. Write identity/autopilot/README.md structuring Autopilot moving parts with Microsoft Learn links <!-- id:8frf0u4 -->
  - Device registration/hardware hash, deployment profiles, Intune enrollment, ESP
  - Stream: 2

- [ ] 4. Add Autopilot config-as-code skeleton (Graph API-based, clearly marked scaffolding) <!-- id:8frf0u5 -->
  - PowerShell/Graph scripts or OpenTofu/Graph provider layout with placeholders showing where profiles and assignments live
  - Stream: 2

## Area docs

- [ ] 5. Write identity/README.md tying the area together <!-- id:8frf0u6 -->
  - Reference existing powershell/ Active Directory and Azure scripts WITHOUT moving them (moves are repo-structure's job)
  - lychee --offline passes on area docs
  - Blocked-by: 8frf0u2 (Write identity/entra/README.md: tenant creation docs portal + CLI with official Microsoft links), 8frf0u3 (Build identity/entra/ OpenTofu root with azuread provider: users, groups, role assignments), 8frf0u4 (Write identity/autopilot/README.md structuring Autopilot moving parts with Microsoft Learn links), 8frf0u5 (Add Autopilot config-as-code skeleton Graph API-based, clearly marked scaffolding)

## Human verification

- [ ] 6. STOP — Create real Entra ID tenant / enrol Autopilot devices (human, billing/global-admin) <!-- id:8frf0u7 -->
  - Deliverables end at validating code and docs
  - Blocked-by: 8frf0u6 (Write identity/README.md tying the area together)
