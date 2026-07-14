---
references:
    - prd.md
---
# Headless Mac setup and repo restructure — repo-structure

## Relocations

- [x] 1. Relocate PowerShell/ to powershell/ via git mv with space-free subdirs <!-- id:1r4styj -->
  - Preserve history: git log --follow traces a sample moved file
  - Do NOT touch macos/, specs/, nextup.md

- [x] 2. Move general-win-use.txt under windows/ (or powershell/docs/) <!-- id:1r4styk -->

## Documentation

- [x] 3. Add area READMEs for relocated content (powershell/, windows/) <!-- id:1r4styl -->
  - Each explains how the area is structured and its conventions
  - Blocked-by: 1r4styj (Relocate PowerShell/ to powershell/ via git mv with space-free subdirs), 1r4styk (Move general-win-use.txt under windows/ or powershell/docs/)

- [x] 4. Rewrite root README.md as file tree + table of contents only <!-- id:1r4stym -->
  - No prose describing what the repo is (one-line title fine)
  - Tree written against the PRD Execution notes authoritative layout (tofu/, azure/, identity/ arrive from sibling contexts)
  - lychee --offline README.md passes
  - Blocked-by: 1r4styj (Relocate PowerShell/ to powershell/ via git mv with space-free subdirs), 1r4styk (Move general-win-use.txt under windows/ or powershell/docs/)

- [x] 5. Integration check: every top-level dir in tree exists and every existing dir appears; per-dir READMEs present <!-- id:1r4styn -->
  - Final reconciliation happens on the integrated branch after all contexts merge
  - Blocked-by: 1r4stym (Rewrite root README.md as file tree + table of contents only)
