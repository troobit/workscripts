---
references:
    - specs/mac-env-setup/requirements.md
    - specs/mac-env-setup/design.md
    - specs/mac-env-setup/decision_log.md
---
# mac-env-setup

## Repo Changes (no script modifications)

- [x] 1. Update aliases.zsh with Podman aliases <!-- id:0pqh9rs -->
  - Stream: 1
  - Requirements: [5.1](requirements.md#5.1), [5.2](requirements.md#5.2), [5.3](requirements.md#5.3), [5.4](requirements.md#5.4), [5.5](requirements.md#5.5)
  - [x] 1.1. Add `alias docker=podman` and `alias docker-compose=podman-compose`
  - [x] 1.2. Replace `dockernuke` alias: use `podman` commands with `2>/dev/null` on each subcommand, `;` separators, end with `podman system prune -af`
  - [x] 1.3. Replace `dockerclear` alias: use `podman` commands with `2>/dev/null` on each subcommand, `;` separators

- [x] 2. Create reference docker-compose.yml <!-- id:0pqh9rt -->
  - Stream: 1
  - Requirements: [4.1](requirements.md#4.1), [4.2](requirements.md#4.2), [4.3](requirements.md#4.3), [4.4](requirements.md#4.4), [4.5](requirements.md#4.5), [4.6](requirements.md#4.6)
  - [x] 2.1. Create `macos/docker-compose.yml` with PostgreSQL 16 Alpine service, named volume `pgdata`, healthcheck
  - [x] 2.2. Add placeholder `app` service on shared `devnet` bridge network, volume mount `./src:/app/src`
  - [x] 2.3. Use env vars with defaults for all config: POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, DB_PORT, APP_PORT
  - [x] 2.4. Add comments documenting prerequisites (`podman machine init/start`) and usage instructions

- [x] 3. Delete macos/path.zsh <!-- id:0pqh9ru -->
  - Stream: 1
  - Requirements: [6.2](requirements.md#6.2)

## Script Modifications (new-mac.sh)

- [ ] 4. Add new packages to default_packages array <!-- id:0pqh9rv -->
  - Stream: 2
  - Requirements: [3.1](requirements.md#3.1), [3.2](requirements.md#3.2), [3.3](requirements.md#3.3), [3.4](requirements.md#3.4), [1.1](requirements.md#1.1)
  - [ ] 4.1. Append `brave-browser`, `whatsapp`, `dockutil` to the `default_packages` array on line 54

- [ ] 5. Add shell config deployment section after logging redirect <!-- id:0pqh9rw -->
  - Blocked-by: 0pqh9rv (Add new packages to default_packages array)
  - Stream: 2
  - Requirements: [6.1](requirements.md#6.1), [6.3](requirements.md#6.3), [6.4](requirements.md#6.4), [6.5](requirements.md#6.5)
  - [ ] 5.1. Add `curl -fsSL -o $HOME/.aliases.zsh` download from repo with `|| echo` guard
  - [ ] 5.2. Add `grep -q` check + append `source ~/.aliases.zsh` line to `~/.zshrc` if not present

- [ ] 6. Add Dock configuration section <!-- id:0pqh9rx -->
  - Blocked-by: 0pqh9rv (Add new packages to default_packages array)
  - Stream: 2
  - Requirements: [1.2](requirements.md#1.2), [1.3](requirements.md#1.3), [1.4](requirements.md#1.4), [1.5](requirements.md#1.5), [1.6](requirements.md#1.6), [2.1](requirements.md#2.1), [2.2](requirements.md#2.2)
  - [ ] 6.1. Define `DOCK_NAMES` and `DOCK_PATHS` indexed arrays (bash 3.2 compatible)
  - [ ] 6.2. Add `command -v dockutil` guard wrapping entire Dock block
  - [ ] 6.3. Add `dockutil --list` snapshot before changes for recovery reference
  - [ ] 6.4. Add `dockutil --remove all --no-restart` with `|| echo` guard
  - [ ] 6.5. Add loop over `DOCK_NAMES`/`DOCK_PATHS` with `[ -d ]` check and `dockutil --add --no-restart`
  - [ ] 6.6. Add `defaults write com.apple.dock show-recents -bool false`
  - [ ] 6.7. Add `killall Dock || true` at end of Dock block

## Verification

- [ ] 7. Create verify-setup.sh script <!-- id:0pqh9ry -->
  - Blocked-by: 0pqh9rw (Add shell config deployment section after logging redirect), 0pqh9rx (Add Dock configuration section)
  - Stream: 2
  - Requirements: [7.1](requirements.md#7.1), [7.2](requirements.md#7.2), [7.3](requirements.md#7.3), [7.4](requirements.md#7.4)
  - [ ] 7.1. Add Dock checks: `dockutil --find` for each app, `defaults read show-recents`
  - [ ] 7.2. Add brew package checks: `brew list --cask` for brave-browser, whatsapp; `brew list` for dockutil, podman, podman-compose
  - [ ] 7.3. Add shell config checks: aliases.zsh exists, sourced in zshrc, docker/docker-compose aliases defined
  - [ ] 7.4. Add compose file existence check

- [ ] 8. Validate docker-compose.yml syntax <!-- id:0pqh9rz -->
  - Blocked-by: 0pqh9rt (Create reference docker-compose.yml)
  - Stream: 1
