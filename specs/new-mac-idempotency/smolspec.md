# new-mac.sh Idempotency

## Overview
`new-mac.sh` failed on first run because `codelayer` is not a valid Homebrew package. Since `brew install` resolves all packages before installing any, the invalid name caused the **entire package batch to fail**, leaving nothing installed. The script continued past this silent failure, skipping all dependent sections (Dock, default browser, login items, Go tools), and eventually exited when `go` was not found. This spec fixes the immediate cause, restructures the package list for maintainability, and makes the install resilient so a single bad package does not block all others.

## Requirements
- The system MUST define all packages in a single, clearly labelled `PACKAGE CONFIGURATION` block at the top of the script (before the interactive phase), so technical users can edit the list before running
- The system MUST separate packages into `packages_formulae` and `packages_casks` arrays (no home/work/default distinction) and install each with the appropriate flag (`brew install --formula` / `brew install --cask`)
- The system MUST remove `codelayer` (not a valid Homebrew package) and `tailscale-app` (invalid name) from the package list
- The system MUST include `python` (latest Homebrew version) in `packages_formulae`
- The system MUST ensure `python3` resolves to the Homebrew-installed version rather than the macOS system Python, by appending `export PATH="$(brew --prefix python)/bin:$PATH"` to `~/.zshrc` (idempotent — only added once)
- The system MUST install formulae and casks as separate `brew install` calls so a cask failure cannot abort formula installation and vice versa
- The system MUST be safely re-runnable: re-running after a partial failure MUST retry any packages not yet installed without re-executing already-completed sections
- The system SHOULD report a clear, actionable warning when any package group fails to install, identifying which group failed and prompting the user to check names before re-running

## Implementation Approach
**File to modify:** `/Users/ronan/repos/workscripts/macos/new-mac.sh`

**Changes already applied:**
1. **Package configuration block** moved to top of script (after `set -e`, before interactive phase) as `packages_formulae` and `packages_casks` arrays
2. **Removed** `codelayer` and `tailscale-app`; **added** `python` to `packages_formulae`; merged `mas` into main formulae list
3. **Replaced** single `brew install "${all_packages[@]}" || echo ...` with two typed calls:
   - `brew install --formula "${packages_formulae[@]}" || echo "⚠️ ..."`
   - `brew install --cask "${packages_casks[@]}" || echo "⚠️ ..."`
4. **Added python3 PATH** — appends `export PATH="$(brew --prefix python)/bin:$PATH"` to `~/.zshrc` with idempotency guard in the shell configuration section

**Remaining implementation work (tasks):**
5. **Resilient install helper** — current `|| echo` still silently continues on failure; replace with batch-then-individual retry: attempt full group first for speed, fall back to per-package on failure, collect `FAILED_PACKAGES` array
6. **Failure summary** — extend Summary section to print `FAILED_PACKAGES` if non-empty
7. **Audit remaining non-standard package names** — verify `logi-options+`, `gcloud-cli`, `lychee`, `anydesk`, etc. are valid Homebrew names

**Existing patterns leveraged:**
- `REPOS_CLONED` / `TOOLS_INSTALLED` counters → extend with `FAILED_PACKAGES` array
- `clone_repo` helper error-capture pattern → same approach for `install_packages` helper
- Existing `command -v dockutil` / `[ -d "/Applications/Brave Browser.app" ]` guards — already idempotent, no change needed

**Dependencies:** No new dependencies.

**Out of Scope:**
- Switching to Brewfile / `brew bundle`
- Changes to `verify-setup.sh`
- Persistent checkpoint files to skip completed sections
- Adding a `--unattended` flag to skip the interactive phase

## Risks and Assumptions
- Risk: Other package names in the list may also be invalid | Mitigation: implementer audits all non-standard names (`logi-options+`, `gcloud-cli`, `lychee`, `anydesk`) with `brew search` before finalising
- Risk: `brew install --formula` will reject cask names placed in the formulae array | Mitigation: arrays are now strictly typed; implementer must not mix types
- Risk: `$(brew --prefix python)` in `.zshrc` evaluates to a path that changes if Python major version is upgraded by Homebrew | Mitigation: `brew --prefix python` resolves the current installed version's prefix; acceptable for personal setup scripts
- Assumption: Re-runs start from the top of the script; existing section guards handle idempotency for all sections except the package install (which `brew install` handles natively)
- Assumption: All other package names are valid — the two confirmed-invalid ones (`codelayer`, `tailscale-app`) have been removed
- Prerequisite: Homebrew must be installed and in PATH before package arrays are used (enforced by lines 20-31 of interactive phase)
