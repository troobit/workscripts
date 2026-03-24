# Mac Setup Guide

## Overview
Create a single comprehensive guide at `docs/new-mac-guide.md` that walks the repo owner through the complete new Mac setup process from unboxing to a fully configured development environment. The guide consolidates all knowledge from `macos/new-mac.sh`, `macos/verify-setup.sh`, and the existing spec documentation into a user-facing document with copy-pasteable commands, script path references, and clear explanations of what each phase does. Target length: 300-500 lines of markdown, readable in 10-15 minutes.

## Requirements
- The guide MUST live at `docs/new-mac-guide.md` as a single self-contained file (implementer must create the `docs/` directory)
- The guide MUST state the minimum macOS version as macOS 15 (Sequoia) — Swift/NSWorkspace APIs work on 12+ but the full Dock layout (iPhone Mirroring) requires 15+
- The guide MUST cover prerequisites: macOS 15+, Apple ID signed into the App Store, internet connection
- The guide MUST present the bootstrap as: fetch the raw script via `curl` from the web (SSH keys don't exist yet on a fresh Mac), then run it — SSH key generation is the first meaningful interactive step after the automated Xcode CLT/Homebrew/gh bootstrap
- The guide MUST include the exact commands to download and run the setup script via `curl` to the raw file URL, formatted as fenced code blocks users can copy
- The guide MUST explain the two-phase structure (interactive vs unattended), listing what happens in each phase so users know when they can walk away
- The guide MUST document what the interactive phase asks for (GitHub noreply email, full name, SSH key generation, GitHub auth via `gh`, sudo password)
- The guide MUST instruct users to enter their GitHub noreply email (e.g., `12345678+username@users.noreply.github.com`) when the script prompts for "GitHub email" — this is found at GitHub Settings → Emails → "Keep my email addresses private"; the same address is used for both `ssh-keygen -C` and `.gitconfig [user] email`
- The guide MUST list all software installed by category (default, home, work, Mac App Store) with brief descriptions for non-obvious tools: bluesnooze, noTunes, dockutil, lychee, cloudflared, ykman, codelayer, yubico-authenticator, uv, mas, raycast
- The guide MUST reference script file paths relative to the repo root (e.g., `macos/new-mac.sh`, `macos/verify-setup.sh`, `macos/aliases.zsh`, `macos/zshrc`, `macos/vimrc`, `macos/docker-compose.yml`, `macos/iterm2-prefs.plist`)
- The guide MUST include the verification command (`bash macos/verify-setup.sh`) and explain its output
- The guide MUST document post-setup manual steps: terminal restart, App Store sign-in for Magnet, Magnet license activation, Raycast configuration, NordVPN login, Bitwarden login, Tailscale login, Dropbox login, Spotify login, Google Drive login, VS Code Settings Sync activation, Logi Options+ device pairing, `.gitconfig` placeholder editing (`SPECIFIC_FOLDER`), and optionally installing full Xcode for Simulator.app
- The guide MUST mention `~/SETUP.log` as the log file for debugging unattended phase issues
- The guide SHOULD include a "What Gets Configured" summary table mapping categories (Dock, system preferences, power, browser, login items, shell, Git, repos, tools) to what the script sets up
- The guide SHOULD document customisation points in a brief section (3-5 bullets) listing the arrays/variables a user would edit to customize the setup, with file paths — not a full tutorial
- The guide SHOULD explain how to opt into `work_packages` (Slack, Teams, Terraform) which are excluded by default
- The guide SHOULD include a troubleshooting section for common issues (Homebrew PATH on Apple Silicon, `mas` requiring App Store sign-in, SSH key already exists, `~/SETUP.log` for debugging)
- The guide MAY include a quick-start section at the top for experienced users who just want the commands

## Proposed Section Outline
```
1. Quick Start (3-4 lines of commands)
2. Prerequisites
3. Getting Started (bootstrap via curl/HTTPS, then run)
4. What Happens: Interactive Phase
5. What Happens: Unattended Phase
6. What Gets Configured (summary table)
7. Software Installed (by category with descriptions)
8. Post-Setup Manual Steps
9. Verification
10. Customisation Points
11. Troubleshooting
```

## Implementation Approach
- **File to create:** `docs/new-mac-guide.md` (new file, new `docs/` directory)
- **Source material:** `macos/new-mac.sh`, `macos/verify-setup.sh`, `macos/aliases.zsh`, `macos/zshrc`, `macos/vimrc`, `macos/docker-compose.yml`, `macos/iterm2-prefs.plist`, `specs/mac-env-setup/design.md`, `specs/mac-env-setup/decision_log.md`, `CHANGELOG.md`
- **Primary audience:** The repo owner setting up their own Mac. The guide should note where values are personal/hardcoded so someone forking can adapt.
- **Pattern:** Follow the structure of the script's own section headers (Interactive Phase -> Unattended Phase -> Summary) as the guide's narrative flow
- **Approach:** Extract user-facing information from the script comments, design doc, and decision log; restructure into a task-oriented guide ("do this, then this") rather than a reference doc
- **Dependencies:** All content derives from existing files in the repo — no external sources needed
- **Out of Scope:** Modifying `new-mac.sh` or any other script; creating additional documentation files; updating the README (can be done separately)

## Risks and Assumptions
- Risk: Guide becomes stale if scripts are updated without updating docs | Mitigation: Include a "Last verified" date and a note that `macos/new-mac.sh` is the source of truth
- Risk: Bootstrap chicken-and-egg — user can't SSH clone before SSH keys exist | Mitigation: Guide uses `curl` to download the script directly, or HTTPS clone as the initial step
- Assumption: Users have a fresh Mac running macOS 15+ (Sequoia) for full feature coverage
- Assumption: The repo is accessible at `github.com/troobit/workscripts` (public or user has access)
- Assumption: The guide is primarily for the repo owner; forked users will need to edit hardcoded values (repos, Dock apps, git identity)
- Prerequisite: `macos/new-mac.sh` and `macos/verify-setup.sh` are complete and merged (they are — all spec tasks are done)
