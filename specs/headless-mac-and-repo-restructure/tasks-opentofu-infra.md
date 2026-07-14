---
references:
    - prd.md
---
# Headless Mac setup and repo restructure — opentofu-infra

## Migration

- [x] 1. Migrate roots from /Users/r/Downloads/tf into tofu/ (copy, source is read-only) <!-- id:is7zc3z -->
  - One directory per root, preserve roots/modules split
  - Drop az_test_workloads (empty); az_hostedrunner is the azure context's (goes to azure/hosted-runner/, not tofu/)
  - Carry or drop .tf.ignore / ignore/ files; record each choice in tofu/README.md

## Convention alignment

- [x] 2. Standardise banner comments to 77-char # === form; preserve inline rationale and commented-out reference blocks <!-- id:is7zc40 -->
  - Blocked-by: is7zc3z (Migrate roots from /Users/r/Downloads/tf into tofu/ copy, source is read-only)
  - Stream: 1

- [x] 3. Rename numbered NN_*.tf files to conventional scheme (main/variables/outputs/providers) <!-- id:is7zc41 -->
  - Blocked-by: is7zc3z (Migrate roots from /Users/r/Downloads/tf into tofu/ copy, source is read-only)
  - Stream: 2

- [x] 4. OpenTofu terminology in all prose; never Terraform for local toolchain <!-- id:is7zc42 -->
  - grep -ri terraform tofu/ --include=*.md returns no local-toolchain hits (provider addresses and quoted workflow snippets exempt)
  - Blocked-by: is7zc3z (Migrate roots from /Users/r/Downloads/tf into tofu/ copy, source is read-only)
  - Stream: 3

## Validation and parameterisation

- [x] 5. Parameterise hardcoded backends/subscriptions into per-env *.backend.hcl with committed *.example files <!-- id:is7zc43 -->
  - Pattern: sanarte environments/{dev,prod}-backend.hcl
  - No real storage-account names, subscription IDs, or role ARNs in .tf files
  - Blocked-by: is7zc3z (Migrate roots from /Users/r/Downloads/tf into tofu/ copy, source is read-only)

- [x] 6. Every root passes tofu fmt -check and tofu init -backend=false + tofu validate <!-- id:is7zc44 -->
  - Blocked-by: is7zc40 (Standardise banner comments to 77-char # === form; preserve inline rationale and commented-out reference blocks), is7zc41 (Rename numbered NN_*.tf files to conventional scheme main/variables/outputs/providers), is7zc43 (Parameterise hardcoded backends/subscriptions into per-env *.backend.hcl with committed *.example files)

## Docs

- [x] 7. Write tofu/README.md <!-- id:is7zc45 -->
  - Layout, comment convention with banner example, backend/tfvars pattern, YAML-driven yamldecode+flatten/for_each pattern
  - lychee --offline passes
  - Blocked-by: is7zc44 (Every root passes tofu fmt -check and tofu init -backend=false + tofu validate)
