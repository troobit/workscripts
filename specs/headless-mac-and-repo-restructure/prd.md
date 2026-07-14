# PRD: Headless Mac setup and repo restructure

## Product summary

This PRD covers two related bodies of work in the `workscripts` repository (a private, personal IT/infrastructure scripts repo). First: refine `macos/new-mac.sh` so a brand-new MacBook can be set up as an always-on headless machine — lid closed in clamshell mode, reachable over SSH/tmux from the local network and a Tailscale tailnet, able to receive git pushes and file copies, and running long-lived tooling (e.g. sdd-ui) so the owner's primary machine can be turned off. The script currently has supervision issues and needs re-running to complete; those defects must be found and fixed.

Second: restructure the repo, which has accumulated years of loosely organised scripts, and amalgamate two external sources into it: the standalone Terraform collection at `/Users/r/Downloads/tf` (~10 independent Azure/AWS roots, 68 `.tf` files) and the Azure Container Apps deployment patterns, GitHub workflows, and agent-instruction templates from `/Users/r/repos/sanarte`. The company works strictly with infrastructure and configuration as code, targeting greenfield environments first and brownfield second. Going forward the toolchain is OpenTofu (locally `tf` is aliased to `tofu`); prose and directory naming must say OpenTofu, while CI workflows and deployment flows keep working as they do today.

The work is done when the repo is organised with a succinct file-tree README, per-platform docs, the migrated IaC validates cleanly, and the repo contains the makings (code plus pointers to official docs) for creating an Entra ID tenant, managing users and RBAC roles, and structuring Windows Autopilot.

## Goals

- `macos/new-mac.sh` completes in one supervised-then-unattended run on a fresh Mac and is safely re-runnable; its known error classes (bad package names silently killing the batch, sections skipped after failures) stay fixed.
- A new Mac configured by the script can run headless: lid closed, never sleeping on AC, auto-restarting after power failure, reachable via SSH and Tailscale, with tmux for persistent sessions and documented file-copy workflows.
- The repo has a clear top-level structure: succinct README (file tree + table of contents only), a doc at the top of each platform/language directory explaining its layout.
- The Terraform collection from `/Users/r/Downloads/tf` lives in this repo under OpenTofu conventions, with the established banner-comment style continued, and every root passing `tofu fmt -check` and `tofu validate`.
- Sanarte's Azure Container Apps deployment patterns, workflows, and templates are available here as reusable, parameterised templates.
- Entra ID (tenant, users, RBAC) and Windows Autopilot have config-as-code groundwork plus docs pointing to the official material needed to execute them for real.

## Non-goals

- No changes to the source locations `/Users/r/Downloads/tf` and `/Users/r/repos/sanarte` — they are read-only sources; content is copied in, never moved out.
- No live Azure deployments, no real tenant creation, no `tofu apply` against any subscription. Everything must validate offline.
- No migration of the brew package list to Brewfile/`brew bundle` (explicitly rejected in a prior spec).
- No CI pipeline for the workscripts repo itself (workflow files land as templates for *other* repos, not as active workflows here).
- No rewriting of sanarte's CI internals: imported workflow templates keep their current deployment flow (including `hashicorp/setup-terraform` usage) — only identifiers are parameterised.
- No actual execution of the new-Mac build inside this work — that is a human step (see STOP points).
- No changes to the four completed specs under `specs/` or to `nextup.md`.

## Mac setup

Covers `macos/` (primarily `new-mac.sh`, `verify-setup.sh`) and a new headless-server guide in `docs/`. Constraint: files under `macos/` MUST NOT be moved or renamed — `new-mac.sh` bootstraps via `curl` from `https://raw.githubusercontent.com/troobit/workscripts/main/macos/...` and self-references those paths (see `new-mac.sh` lines 200–228).

1. The script MUST be audited for obvious errors and re-run/supervision defects, and each found defect fixed.
   - Acceptance: `shellcheck macos/new-mac.sh macos/verify-setup.sh` reports no errors (warnings triaged or directive-suppressed with a reason).
   - Acceptance: known suspect constructs are resolved — e.g. `echo "\n..."` bashism (line 209) writes a literal `\n` into `~/.zshrc`; the `set -e` + `exec > >(tee ...)` + background sudo keep-alive interplay; the Swift heredoc block's failure path.
   - Acceptance: a second run on an already-configured machine completes without error and without duplicating lines in `~/.zshrc` or `~/.gitconfig` (documented dry-run reasoning or a VM/container check is acceptable evidence where a real second Mac is unavailable).
2. The script MUST install and bring up Tailscale.
   - Acceptance: the package name used is verified valid via `brew info` (a prior fix removed the invalid name `tailscale-app`; the correct formula/cask must be confirmed, not guessed).
   - Acceptance: `tailscale up` (or its App variant login) is placed in the interactive phase or the post-run checklist, since it needs a browser sign-in.
3. The script MUST enable remote access for headless operation.
   - Acceptance: Remote Login (SSH) is enabled via `sudo systemsetup -setremotelogin on` (or equivalent), idempotently.
   - Acceptance: the new guide documents how to reach the machine by hostname/IP on the local network and via its Tailscale name.
4. The script MUST configure always-on clamshell operation.
   - Acceptance: on AC power the machine does not sleep with the lid closed (e.g. `sudo pmset -a disablesleep 1` or an equivalent documented mechanism), and the choice is explained in a comment.
   - Acceptance: auto-restart after power failure is enabled (`sudo systemsetup -setrestartpowerfailure on` or `pmset autorestart`).
   - Acceptance: `macos/verify-setup.sh` gains checks for remote login, Tailscale presence, and the always-on power settings.
5. The script MUST account for provider sign-ins needed on the new machine: GitHub (`gh auth login`, already present), Claude Code (`claude` login), Tailscale, and the App Store (for `mas`).
   - Acceptance: every sign-in that is inherently interactive either happens in the interactive phase or appears in a single consolidated "manual sign-ins" checklist printed at the end of the run and repeated in the guide.
6. A guide `docs/new-mac-localhost.md` MUST document the headless workflow end to end.
   - Acceptance: it covers bootstrap (curl one-liner), the interactive phase, the sign-in checklist, connecting from another Mac (ssh, `tmux new -A -s main` for persistent sessions), copying files both directions (scp/rsync examples), pushing to repos on the machine, and running long-lived processes (launchd/tmux) such as sdd-ui.
   - Acceptance: `lychee --offline` passes on the guide's local links.
7. The docs SHOULD reconcile with the existing `docs/new-mac-guide.md` rather than duplicating it.
   - Acceptance: overlapping content lives in one place; the other file links to it.

## Repo structure

Covers the repo root: `README.md`, top-level directory layout, and relocation of existing loose content (`PowerShell/`, `general-win-use.txt`). Owns `README.md` exclusively — no other context edits it. MUST NOT move anything under `macos/` (raw-URL paths are load-bearing) and MUST NOT touch `specs/` or `nextup.md`.

1. The repo MUST adopt the target layout defined in Execution notes, moving existing content with `git mv` so history is preserved.
   - Acceptance: `PowerShell/` content lives under `powershell/` with subdirectory names free of spaces; `general-win-use.txt` lives under `windows/` (or `powershell/docs/`) rather than the repo root.
   - Acceptance: `git log --follow` still traces a sample moved file's history.
2. `README.md` MUST be succinct: a file tree of the top-level structure and a table of contents linking each area's own doc — no description of what the repo is, no marketing prose.
   - Acceptance: the README contains no paragraph describing the repo's purpose; it is only tree + links (a one-line title is fine).
   - Acceptance: `lychee --offline README.md` passes.
3. Each top-level platform/language directory MUST open with a doc (`README.md` inside that directory) explaining how that area is structured and any conventions specific to it.
   - Acceptance: `macos/`, `powershell/`, `tofu/`, `azure/`, `identity/`, and `windows/` (if created) each contain a README; where another context authors that README (tofu, azure, identity), this context only verifies presence at integration.
4. The root README's tree MUST reflect the final merged layout including directories created by the other contexts.
   - Acceptance: every top-level directory in the tree exists, and every existing top-level directory appears in the tree.

## OpenTofu infra

Covers a new `tofu/` directory populated from `/Users/r/Downloads/tf` (read-only source). ~10 independent roots: `aws/simple_ec2`, `aws/vpc`, `az_container_webapp/terraform` (+ modules `vnet`, `containerapp`, `umid`), `az_monitoring`, `az_pep_service`, `az_private_endpoints` (+ module `private-link-endpoint`), `az_vnet` (+ `delegation`, `peering`), `az_webserver`, plus the non-Terraform `az_hostedrunner` (Docker) and the empty `az_test_workloads`.

1. The context MUST migrate the roots into `tofu/`, one directory per root, preserving the roots/modules split.
   - Acceptance: every root from the source appears under `tofu/` except `az_test_workloads` (empty — dropped) ; `az_hostedrunner` moves under `azure/hosted-runner/` instead (it is Docker, not IaC) — coordinate paths only via this PRD, not by editing the other context's files.
   - Acceptance: files disabled in the source via `.tf.ignore` suffixes or `ignore/` directories are either carried over unchanged as reference or dropped, and the choice per file is recorded in `tofu/README.md`.
2. The established banner-comment style MUST be continued and standardised.
   - Acceptance: section banners use the `# ===...===` form standardised to the 77-character width used by `az_container_webapp` and sanarte, e.g.:
     ```hcl
     # =============================================================================
     # Container App Environment
     # =============================================================================
     ```
   - Acceptance: terse lowercase inline rationale comments and intentionally commented-out reference blocks in the source are preserved, not stripped.
3. File naming MUST be reconciled to the conventional scheme (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`/`versions.tf`, plus per-feature files), replacing the numbered `00_Providers.tf` scheme in older roots.
   - Acceptance: no `NN_*.tf` files remain under `tofu/`; renames keep resource content intact.
4. All prose (READMEs, comments describing the toolchain) MUST use OpenTofu terminology, never "Terraform", when referring to this repo's `.tf` usage; `tf` is assumed aliased to `tofu` locally. Provider source addresses, `required_providers` blocks, and imported CI workflow internals stay as they are.
   - Acceptance: `grep -ri terraform tofu/ --include='*.md'` returns no hits describing the local toolchain (hits inside provider addresses or quoted workflow snippets are exempt).
5. Every root MUST validate offline.
   - Acceptance: for each root, `tofu fmt -check` passes and `tofu init -backend=false && tofu validate` succeeds.
6. Hardcoded backend and subscription values MUST be parameterised for greenfield reuse.
   - Acceptance: backend blocks take their config from per-environment `*.backend.hcl` files (pattern: sanarte's `environments/{dev,prod}-backend.hcl`), with committed `*.example` files and no real storage-account names, subscription IDs, or role ARNs hardcoded in `.tf` files.
7. `tofu/README.md` MUST document the directory layout, the comment convention (with the banner example), the backend/tfvars pattern, and the YAML-driven config pattern (`yamldecode` + `flatten`/`for_each` used by `az_vnet` and `aws/vpc`).
   - Acceptance: the README exists and `lychee --offline` passes on it.

## Azure patterns

Covers a new `azure/` directory populated from `/Users/r/repos/sanarte` (read-only source): reusable Container Apps deployment patterns, GitHub workflow templates, and agent-instruction templates.

1. The four sanarte workflows (`build-container.yml`, `deploy-container-app.yml`, `tf-deploy.yml`, `update-kv-secret.yml`) MUST be imported as parameterised templates under `azure/github-workflows/`, not under this repo's own `.github/workflows/`.
   - Acceptance: sanarte-specific identifiers (client/tenant/subscription IDs, `rg-sanarte-prod`, `ca-sanarte-prod`, `ghcr.io/troobit/sanarte`, hardcoded ARM env values in `tf-deploy.yml`) are replaced with `${{ vars.* }}`/`${{ secrets.* }}` references or clearly marked placeholders.
   - Acceptance: the auth inconsistency is normalised — all four templates use the same mechanism (repo `vars`, as three of four already do) instead of `update-kv-secret.yml`'s `secrets.*` variant; the dead `workflow_run` trigger name in `update-kv-secret.yml` is fixed or removed.
   - Acceptance: each template parses (`yq eval` or `actionlint` where available).
2. The Container Apps deployment pattern MUST be captured as a reusable set under `azure/container-apps/`.
   - Acceptance: includes a generalised declarative app YAML (from `config/frontend.yml`), the local deploy script pattern (`scripts/deploy.sh`), and the OIDC bootstrap script (`infrastructure/terraform/scripts/setup_permissions.sh`), each with placeholders instead of sanarte values.
   - Acceptance: the tfstate firewall open/close pattern from `tf-deploy.yml` and the deploy-by-immutable-digest pattern are described in the area README.
3. `az_hostedrunner` from `/Users/r/Downloads/tf` MUST land under `azure/hosted-runner/` unchanged apart from a short header note on provenance.
   - Acceptance: Dockerfile, compose file, and requirements are present and referenced from the area README.
4. The sanarte agent-customisation templates SHOULD be imported under `azure/agent-templates/` (chatmodes, instructions, prompts — e.g. `azure-principal-architect.chatmode.md`, `terraform-use.md`, `devplan.instructions.md`).
   - Acceptance: files carry their YAML front-matter intact and the area README says what they are for.
5. `azure/README.md` MUST explain the layout and how the patterns apply to greenfield (primary) and brownfield (secondary) environments, including the OIDC/user-assigned-managed-identity auth model.
   - Acceptance: README exists, covers OIDC federation (why no client secrets), and `lychee --offline` passes.

## Identity

Covers a new `identity/` directory: the Entra ID and Windows Autopilot groundwork that defines this PRD's done-bar. Config-as-code plus docs; nothing is applied against a real tenant.

1. The context MUST provide Entra ID tenant groundwork: documentation for creating a tenant plus OpenTofu configuration for what is codifiable inside one.
   - Acceptance: `identity/entra/README.md` documents tenant creation steps (portal and CLI) with links to the official Microsoft docs, and is explicit that tenant creation itself is a manual/billing-gated step.
   - Acceptance: `identity/entra/` contains an OpenTofu root using the `azuread` provider covering users, groups, and directory role / RBAC role assignments, following the data-driven `for_each` role-assignment pattern from sanarte's `umid` module and the repo banner-comment style.
   - Acceptance: the root passes `tofu fmt -check` and `tofu init -backend=false && tofu validate`.
2. The context MUST provide Windows Autopilot groundwork — at minimum the makings and pointers to official documentation.
   - Acceptance: `identity/autopilot/README.md` structures the moving parts (device registration/hardware hash, deployment profiles, Intune enrollment, ESP) and links each to current official Microsoft Learn documentation.
   - Acceptance: a config-as-code skeleton exists (Graph API-based — PowerShell scripts or an OpenTofu/Graph provider layout with placeholders) showing where profiles and assignments would live, clearly marked as scaffolding.
3. `identity/README.md` MUST tie the area together and reference the related existing scripts under `powershell/` (e.g. the Active Directory and Azure scripts) without moving them — moves are the Repo structure context's job.
   - Acceptance: README exists and `lychee --offline` passes on the area's docs.

## Execution notes

- Quality gates (no Makefile in this repo): `shellcheck` on every touched `.sh`; `bash -n` as a smoke check; `tofu fmt -check` and `tofu init -backend=false && tofu validate` per OpenTofu root; `lychee --offline` on touched markdown; `yq eval` (or `actionlint` if installed) on workflow templates. Prefix runs with `run_silent` where available.
- Target top-level layout (authoritative for all contexts):
  ```
  README.md        # tree + TOC only (Repo structure context owns this file)
  CHANGELOG.md
  docs/            # cross-cutting guides (new-mac-guide.md, new-mac-localhost.md)
  macos/           # unchanged paths — raw-URL load-bearing
  powershell/      # relocated from PowerShell/
  windows/         # general Windows notes (general-win-use.txt)
  tofu/            # OpenTofu roots + modules (from ~/Downloads/tf)
  azure/           # deployment patterns, workflow templates, hosted-runner (from sanarte)
  identity/        # Entra ID + Autopilot groundwork
  specs/           # untouched
  ```
- Source directories `/Users/r/Downloads/tf` and `/Users/r/repos/sanarte` are read-only references: copy, never modify.
- File-ownership boundaries: `README.md` (root) is written only by Repo structure; `macos/` only by Mac setup; `tofu/` only by OpenTofu infra; `azure/` only by Azure patterns; `identity/` only by Identity; root-level moves (`PowerShell/`, `general-win-use.txt`) only by Repo structure. `docs/new-mac-localhost.md` belongs to Mac setup.
- Ordering: Repo structure's final README tree must be reconciled at integration time, after the other contexts' directories exist. All other contexts are mutually independent.
- Comment style is a repo-wide convention for `.tf` work: 77-character `# ===` banners with a title line, terse lowercase inline rationale. The OpenTofu infra section quotes the canonical example.
- STOP — the brand-new Mac build itself is a human step: running `macos/new-mac.sh` on the physical machine, entering credentials, and completing the interactive sign-ins (GitHub, Claude, Tailscale, App Store) cannot be done by an agent. The deliverable is the refined script, verify checks, and `docs/new-mac-localhost.md`; the owner executes the build against it.
- STOP — creating a real Entra ID tenant, assigning licences, and enrolling Autopilot devices require a human with billing/global-admin access. The deliverable is validating code and docs only.
