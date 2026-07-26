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

## macOS config sync + skup (`specs/skup`)

- **`sync-config.sh` and `skup` are dual-mode**: guarded by `[ "${BASH_SOURCE[0]}" = "${0}" ]`, so sourcing a file exposes its functions without running `main`. Tests under `macos/tests/` source them to exercise helpers directly. When re-sourcing `skup` from another script, pass a sentinel `$0` (not the skup path) or the guard sees `BASH_SOURCE[0] == $0` and launches `skup_main` (tmux).
- **`verify-setup.sh` is the converged-state harness** (Req 3.5): it asserts the linked end state after `sync-config.sh` runs. Running the *whole* script against a real `$HOME` hangs on the system-check sections (`osascript` login items / automation prompt, `sudo`, `pmset`). To validate just the skup assertions, point `$HOME` at a sandbox, run `sync-config.sh`, then run only the `=== skup: ... ===` sections. `MACOS_DIR` derives from `$0`, so any extract-to-temp harness must override it to the real `macos/` dir.
- **Corrupted-`tk` gotcha**: `aliases.zsh` documents the old broken `tmux kill~session ~t` form in a *comment*. Absence checks must match the alias *definition* (`alias tk='tmux kill~session`), not the bare substring, or the comment trips a false positive.
- **Idempotency is tested behaviourally** (`macos/tests/idempotency.sh`): run `sync-config.sh` twice against a sandbox `$HOME`; the second run must create no new backup and leave `~/.zshrc` byte-identical.

## Quality gates (no Makefile)

`shellcheck` + `bash -n` on shell scripts; `tofu fmt -check` and `tofu init -backend=false && tofu validate` per root (11 roots incl. `identity/entra`); `lychee --offline` on markdown; `yq eval` on workflow templates.
