# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Added `install_packages` resilient helper to `macos/new-mac.sh`: attempts batch install first for speed, falls back to per-package retry on failure, collects failed names in `FAILED_PACKAGES` array
- Added `FAILED_PACKAGES` summary to Setup Summary section in `macos/new-mac.sh`: lists failed package names with `brew info <name>` diagnostic hint and re-run instructions
- Added `specs/new-mac-idempotency/` smolspec and task list for the resilient package install feature

### Changed
- Replaced direct `brew install --formula ... || echo` and `brew install --cask ... || echo` calls in `macos/new-mac.sh` with `install_packages` helper that provides per-package retry and failure tracking

### Added
- Added Verification section to `docs/new-mac-guide.md`: documents `bash macos/verify-setup.sh` command, lists all 9 check categories with descriptions, and explains pass/fail output format
- Added Customisation Points section to `docs/new-mac-guide.md`: 5-bullet guide to editing `default_packages`/`home_packages`, `work_packages`, `DOCK_NAMES`/`DOCK_PATHS`, `LOGIN_APPS`, and `clone_repo` calls with line references
- Added Troubleshooting section to `docs/new-mac-guide.md`: covers Homebrew PATH on Apple Silicon, `mas` requiring App Store sign-in, SSH key already exists, and `~/SETUP.log` for debugging
- Added Interactive Phase and Unattended Phase sections to `docs/new-mac-guide.md`: documents the two-phase script structure including all interactive prompts (GitHub noreply email, full name, SSH key, sudo), noreply email guidance with link, walk-away banner, and full list of unattended operations with `~/SETUP.log` reference
- Added Software Installed section to `docs/new-mac-guide.md`: complete inventory of all packages by category (default, home, work, Mac App Store) with descriptions for non-obvious tools (bluesnooze, noTunes, dockutil, lychee, cloudflared, ykman, codelayer, yubico-authenticator, uv, mas, raycast) and opt-in instructions for work_packages
- Added What Gets Configured summary table to `docs/new-mac-guide.md`: maps 13 categories (Dock, system preferences, power, browser, login items, shell, Git, Vim, repositories, Go tools, Claude Code, iTerm2, containers) to script actions and source file paths
- Added Post-Setup Manual Steps section to `docs/new-mac-guide.md`: checklist covering terminal restart, App Store sign-in, Magnet licensing, app logins (NordVPN, Bitwarden, Tailscale, Dropbox, Spotify, Google Drive), configuration syncs (VS Code Settings Sync, Raycast, Logi Options+), `.gitconfig` placeholder editing, and optional full Xcode installation
- Created `docs/new-mac-guide.md` with Quick Start (curl commands), Prerequisites (macOS 15+, Apple ID, internet), and Getting Started sections documenting the HTTPS bootstrap problem and SSH key generation flow
- Added `specs/mac-setup-guide/` smolspec and task list for the new Mac setup guide

### Added
- Expanded `macos/verify-setup.sh` with comprehensive verification: Dock app checks for all 16 apps via `dockutil --find`, Dock preference checks (tilesize, magnification, largesize, autohide, show-recents), system preference checks (hot corner, accent color, Mission Control, Finder view), power management checks via `pmset -g custom` parsing, default browser check via LaunchServices plist, login items checks via `osascript` query, and expanded Homebrew package spot-checks (bat, fzf, tmux, mas, dockutil)
- Added iTerm2 preferences export (`macos/iterm2-prefs.plist`) and import section in `macos/new-mac.sh`: checks for plist file and iTerm2 installation, imports via `defaults import com.googlecode.iterm2` with `|| echo` guard
- Added D31 to `specs/mac-env-setup/decision_log.md` documenting app-level settings automation limitations (Magnet license verification, Raycast encryption, NordVPN/Bitwarden interactive login, VS Code Settings Sync)

### Added
- Added system preferences section to `macos/new-mac.sh`: hot corner (bottom-right Quick Note), accent color (Pink), highlight color (Green), Mission Control settings (group by app, disable auto-rearrange spaces), Finder column view default, with `killall Finder || true` to apply changes
- Updated Dock configuration in `macos/new-mac.sh` from 4 apps to full 16-app layout with 2 spacer tiles using `SPACER` sentinel pattern in indexed arrays; added Downloads folder to persistent-others section; added Dock preferences (`tilesize 44`, `magnification true`, `largesize 128`, `autohide true`)
- Added power management section to `macos/new-mac.sh`: AC power never-sleep (`displaysleep 0`, `sleep 0`), battery conservative sleep (`displaysleep 10`, `sleep 1`) via `sudo pmset` with `|| echo` guards
- Added default browser section to `macos/new-mac.sh`: sets Brave Browser as default via Swift/NSWorkspace API (`setDefaultApplication(at:toOpenURLsWithScheme:)` for `http` and `https`), background AppleScript auto-dismisses CoreServicesUIAgent confirmation dialog, guarded by app existence check
- Added login items section to `macos/new-mac.sh`: defines 6 utility apps (Caffeine, noTunes, Magnet, Bluesnooze, Google Drive, Raycast), queries existing login items once via `osascript`, adds missing items with `[ -d ]` existence checks and `grep -qi` deduplication

### Changed
- Replaced `default_packages` array in `macos/new-mac.sh` with 26 packages: 12 formulae (`bat`, `fzf`, `gh`, `git`, `htop`, `jq`, `rename`, `tmux`, `tree`, `wget`, `yq`, `go`) and 14 casks (`bluesnooze`, `brave-browser`, `caffeine`, `claude-code`, `dockutil`, `firefox`, `gimp`, `google-chrome`, `iterm2`, `nordvpn`, `notunes`, `raycast`, `visual-studio-code`, `whatsapp`); added inline `# Formulae` / `# Casks` comments
- Replaced `home_packages` array in `macos/new-mac.sh` with 29 packages: 11 formulae (`awscli`, `azure-cli`, `cloudflared`, `lychee`, `mas`, `nvm`, `opentofu`, `podman`, `podman-compose`, `uv`, `ykman`) and 18 casks (`anydesk`, `audacity`, `bitwarden`, `codelayer`, `dropbox`, `gcloud-cli`, `github`, `google-drive`, `inkscape`, `logi-options+`, `postman`, `spotify`, `stremio`, `tailscale-app`, `transmission`, `vlc`, `wireshark`, `yubico-authenticator`); added inline comments
- Updated `all_packages` comment to clarify `work_packages` are excluded by design

### Added
- Added Mac App Store installation section after `brew install` in `macos/new-mac.sh`: checks for `mas` availability via `command -v`, verifies Magnet (ID 441258766) not already installed via `mas list | grep -q`, installs with `|| echo` guard and App Store sign-in warning

### Added
- Restructured `macos/new-mac.sh` into two distinct phases: interactive (Xcode, Homebrew, user input, SSH keys, sudo credentials) followed by unattended (packages, config, Dock, repos, tools) with a "walk away" banner marking the transition
- Added early `brew install gh` in the interactive phase so GitHub CLI is available for SSH key setup before full package installation
- Added sudo keep-alive mechanism: `sudo -v` prompt during interactive phase with background `while true; do sudo -n true; sleep 60; done` loop, PID stored in `SUDO_KEEPALIVE_PID`, `trap EXIT` safety net, and explicit kill in summary section
- Added v2 design decisions (D23–D30) to `specs/mac-env-setup/decision_log.md` covering script restructuring, sudo keep-alive, default browser via Swift/NSWorkspace, full Dock layout with SPACER sentinel, login items via osascript, power management values, scoped-out items, and Mac App Store via mas
- Added v2 requirements and design documents for mac-env-setup covering Dock layout, system preferences, power management, default browser, login items, package reconciliation, and app-level settings

### Fixed
- Corrected Dock app name from `iTerm` to `iTerm2` in `macos/new-mac.sh` to match the actual application name

- Added VS Code keyboard shortcut reference files for macOS: `vsc-shortcuts-gem.md` (concise AI-focused cheat sheet), `vsc-shortcuts-gpt.md` (comprehensive guide with Claude Code and Copilot shortcuts), `vsc-shortcuts-gpt52.md` (extended guide including vim-style shortcuts and focus recipes), and `vsc-shortcuts-msft.pdf` (Microsoft official reference)

### Fixed
- Corrected Dock app name from `iTerm` to `iTerm2` in `macos/new-mac.sh` to match the actual application name

- Added `brave-browser`, `whatsapp`, and `dockutil` to the `default_packages` array in `macos/new-mac.sh`
- Added shell configuration deployment section to `macos/new-mac.sh`: downloads `aliases.zsh` from the repo to `~/.aliases.zsh` (overwrite on re-run), appends `source ~/.aliases.zsh` to `~/.zshrc` with idempotent `grep -q` guard
- Added Dock configuration section to `macos/new-mac.sh`: snapshots current Dock state, removes all items via `dockutil --remove all --no-restart`, adds Brave Browser, WhatsApp, iTerm, and Calendar with `[ -d ]` path checks, disables recent apps via `defaults write`, restarts Dock with `killall Dock || true`; entire block guarded by `command -v dockutil` check
- Added `macos/docker-compose.yml` reference compose file with PostgreSQL 16 Alpine service, placeholder app service, shared `devnet` bridge network, named volume `pgdata`, healthcheck, and env vars with defaults for all config values
- Added `docker='podman'` and `docker-compose='podman-compose'` aliases to `macos/aliases.zsh`
- Added `macos/verify-setup.sh` verification script with checks for Dock configuration, Homebrew packages, shell config deployment, alias definitions, and compose file existence

### Changed
- Updated `dockernuke` alias to use `podman` commands with `2>/dev/null` error suppression, `;` separators, and `podman system prune -af` instead of `docker-buildx prune`
- Updated `dockerclear` alias to use `podman` commands with `2>/dev/null` error suppression and `;` separators

### Removed
- Deleted `macos/path.zsh` — pnpm PATH handled by `brew install pnpm`, Homebrew PATH set via `eval "$(/opt/homebrew/bin/brew shellenv)"`, NVM not installed

---

## [Previous]

### Added
- Added `gh` (GitHub CLI) and `go` to `default_packages` in `macos/new-mac.sh` to support GitHub authentication and Go tool installation during Mac setup
- Added logging initialization to `macos/new-mac.sh`: all developer setup output is tee'd to `~/SETUP.log`
- Added dependency verification in `macos/new-mac.sh`: checks that `gh`, `go`, and `git` are available after Homebrew install, exits with a clear error if any are missing
- Added upfront user input prompts in `macos/new-mac.sh`: collects `GITHUB_EMAIL` and `GIT_NAME` with non-empty validation before proceeding with developer setup
- Added SSH key setup section in `macos/new-mac.sh`: generates an ED25519 key at `~/.ssh/github`, starts ssh-agent, adds the key, authenticates with GitHub via `gh auth login --web`, deduplicates before uploading the public key, and tests the SSH connection to github.com
- Added Git configuration setup section in `macos/new-mac.sh`: checks if `~/.gitconfig` exists, skips if already present, otherwise writes an embedded gitconfig template populated with `$GIT_NAME` and `$GITHUB_EMAIL` including user identity, SSH command, push/pull/init settings, pager config, and Git LFS filters
- Added `~/repos/` directory creation in `macos/new-mac.sh`: idempotent `mkdir -p` with skip-if-exists check and status logging
- Added `clone_repo` helper function and clone calls for four repositories (`troobit/workscripts`, `ArjenSchwarz/rune`, `ArjenSchwarz/orbit`, `ArjenSchwarz/agentic-coding`) into `~/repos/` via SSH, with per-repo skip-if-cloned check and a `REPOS_CLONED/REPOS_TOTAL` summary counter
- Added Claude Code skills symlink setup in `macos/new-mac.sh`: creates `~/.claude` directory if needed, then checks `~/.claude/skills` for three states — correct symlink (skip), wrong target or non-symlink (warn to stderr), or absent (create via `ln -s`); skips entirely if `agentic-coding` was not cloned
- Added Go tool installation section in `macos/new-mac.sh`: `install_tool` helper tries `make install` first (if Makefile exists), falls back to `go install ./...`, skips if the repository was not cloned, tracks `TOOLS_INSTALLED/TOOLS_TOTAL` counter, and is called for `rune` and `orbit`
- Added PATH and tool availability verification after Go tool installation: warns to stderr if `~/go/bin` is not in `$PATH`, then checks that each of `rune` and `orbit` is accessible via `command -v`
- Added setup summary block at end of `macos/new-mac.sh`: prints `REPOS_CLONED/REPOS_TOTAL` and `TOOLS_INSTALLED/TOOLS_TOTAL` counts, then emits a success or warning message depending on whether any repos or tools were set up successfully

### Changed
- Renamed spec directory from `specs/repos-setup/` to `specs/repo-setup/` for consistency
- Updated final success message in `macos/new-mac.sh` to include counts inline: "Successfully set up X/Y repositories, symlink, and X/Y tools" (per requirement 9.8); added `SYMLINK_SETUP` tracking variable to the symlink section so the message conditionally includes symlink status
