# Repo layout and conventions

Established 2026-07-14 by the `headless-mac-and-repo-restructure` PRD (see `specs/headless-mac-and-repo-restructure/prd.md` for the full rationale).

## Layout

Top-level dirs are per-platform areas, each with its own `README.md`: `macos/`, `powershell/`, `windows/`, `tofu/`, `azure/`, `identity/`. The root `README.md` is deliberately only a file tree + TOC (private repo — no purpose prose).

## Gotchas

- **`macos/` paths are load-bearing**: `new-mac.sh` curls `raw.githubusercontent.com/troobit/workscripts/main/macos/...` at bootstrap and self-references those paths. Never move or rename files under `macos/`.
- **OpenTofu, not Terraform**: prose and docs say OpenTofu; `tf` is aliased to `tofu` locally. Provider addresses, `required_providers`, and imported CI workflow internals keep their original `terraform` naming — that is intentional, not an oversight.
- **`.tf` comment convention**: 77-char `# ===` banner headers plus terse lowercase inline rationale comments; intentionally commented-out reference blocks are kept, not stripped. Canonical example in `tofu/README.md`.
- **Backends are parameterised**: real backend config lives in gitignored `environments/*-backend.hcl`; only `.example` files are committed. No real subscription IDs / storage accounts / role ARNs in `.tf` files.
- **`azure/github-workflows/` are templates for other repos** — they must never live under this repo's own `.github/workflows/` or they would execute here.

## Quality gates (no Makefile)

`shellcheck` + `bash -n` on shell scripts; `tofu fmt -check` and `tofu init -backend=false && tofu validate` per root (11 roots incl. `identity/entra`); `lychee --offline` on markdown; `yq eval` on workflow templates.
