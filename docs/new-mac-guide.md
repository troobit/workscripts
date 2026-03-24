# New Mac Setup Guide

> Last verified: 2026-03-24 | Source of truth: `macos/new-mac.sh`

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/troobit/workscripts/main/macos/new-mac.sh -o /tmp/new-mac.sh
chmod +x /tmp/new-mac.sh
bash /tmp/new-mac.sh
```

## Prerequisites

- **macOS 15+ (Sequoia)** — the full Dock layout (including iPhone Mirroring) requires macOS 15; underlying Swift/NSWorkspace APIs work on 12+
- **Apple ID signed into the App Store** — required for `mas` (Mac App Store CLI) to install apps like Magnet
- **Internet connection** — the script downloads Homebrew, packages, Oh My Zsh, shell configs, and clones Git repositories

## Getting Started

On a fresh Mac, SSH keys don't exist yet — so you can't `git clone` via SSH. Instead, bootstrap by fetching the setup script directly over HTTPS using `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/troobit/workscripts/main/macos/new-mac.sh -o /tmp/new-mac.sh
chmod +x /tmp/new-mac.sh
bash /tmp/new-mac.sh
```

The script begins with an automated bootstrap that installs Xcode Command Line Tools, Homebrew, and `gh` (GitHub CLI) — all without requiring SSH access. Once those are in place, the first meaningful interactive step is **SSH key generation**: the script creates an Ed25519 key at `~/.ssh/github`, starts the SSH agent, and authenticates with GitHub via `gh auth login`. From that point on, all Git operations (repository cloning, etc.) use SSH.

## What Happens: Interactive Phase

The interactive phase requires you to be present at the keyboard. The script handles bootstrap dependencies automatically, then prompts you for input:

1. **Auto-installs Xcode CLT and Homebrew** — if not already present, these are installed without prompting (Xcode CLT may show a system dialog)
2. **Installs `gh` (GitHub CLI)** — needed for SSH key upload and GitHub authentication
3. **Prompts for your GitHub noreply email** — enter the address from [GitHub Settings → Emails → "Keep my email addresses private"](https://github.com/settings/emails), e.g. `12345678+username@users.noreply.github.com`. This is used for both `ssh-keygen -C` and `.gitconfig [user] email`
4. **Prompts for your full name** — used in `.gitconfig [user] name`
5. **Generates an SSH key** — creates an Ed25519 key at `~/.ssh/github`, adds it to the SSH agent, authenticates with GitHub via `gh auth login` (opens a browser), and uploads the public key
6. **Prompts for your sudo password** — needed for system-level configuration (power management). A background keep-alive process maintains the sudo session for the rest of the script

Once you enter your sudo password, the script prints:

```
🚀 Unattended phase starting — you can walk away now
```

## What Happens: Unattended Phase

After the banner, no further input is required. You can walk away while the script:

- Updates Homebrew and installs all packages (formulae and casks)
- Installs the Nerd Font (Droid Sans Mono) and Oh My Zsh with plugins
- Installs Mac App Store apps via `mas` (Magnet)
- Downloads and deploys shell configuration (`.vimrc`, `.zshrc` additions, `aliases.zsh`)
- Configures system preferences (hot corners, accent colour, Mission Control, Finder)
- Sets up the Dock layout with spacers and preferences (auto-hide, magnification, tile size)
- Configures power management (AC: never sleep; battery: conservative)
- Sets Brave Browser as the default browser (auto-dismisses the confirmation dialog)
- Adds login items (Caffeine, noTunes, Magnet, Bluesnooze, Google Drive, Raycast)
- Creates `.gitconfig` with your name, email, SSH key path, and conditional includes
- Creates `~/repos/` and clones repositories via SSH
- Sets up the Claude Code skills symlink
- Installs Go tools (`rune`, `orbit`) via `make install` or `go install`
- Imports iTerm2 preferences from `macos/iterm2-prefs.plist`

All output from the unattended phase is logged to **`~/SETUP.log`** — check this file if anything goes wrong.

## Software Installed

The script installs packages in three categories. By default, `default_packages` and `home_packages` are combined. `work_packages` are excluded unless you opt in.

### Default Packages

| Package | Type | Description |
|---------|------|-------------|
| bat | Formula | `cat` replacement with syntax highlighting |
| fzf | Formula | Fuzzy finder for the terminal |
| gh | Formula | GitHub CLI |
| git | Formula | Version control |
| go | Formula | Go programming language |
| htop | Formula | Interactive process viewer |
| jq | Formula | JSON processor |
| rename | Formula | Batch file renaming |
| tmux | Formula | Terminal multiplexer |
| tree | Formula | Directory listing as a tree |
| wget | Formula | HTTP file downloader |
| yq | Formula | YAML/XML/TOML processor (like jq) |
| bluesnooze | Cask | Disables Bluetooth when Mac sleeps to prevent phantom wake-ups |
| brave-browser | Cask | Privacy-focused Chromium browser (set as default) |
| caffeine | Cask | Prevents Mac from sleeping (menu bar toggle) |
| claude-code | Cask | Claude Code AI assistant |
| dockutil | Cask | CLI tool for managing Dock items programmatically |
| firefox | Cask | Web browser |
| gimp | Cask | Image editor |
| google-chrome | Cask | Web browser |
| iterm2 | Cask | Terminal emulator |
| nordvpn | Cask | VPN client |
| notunes | Cask | Prevents Apple Music from launching when media keys are pressed |
| raycast | Cask | Spotlight replacement with extensions, clipboard history, and window management |
| visual-studio-code | Cask | Code editor |
| whatsapp | Cask | Messaging app |

### Home Packages

| Package | Type | Description |
|---------|------|-------------|
| awscli | Formula | AWS command-line interface |
| azure-cli | Formula | Azure command-line interface |
| cloudflared | Formula | Cloudflare Tunnel client for exposing local services securely |
| lychee | Formula | Fast link checker for markdown, HTML, and URLs |
| mas | Formula | Mac App Store CLI — installs App Store apps from the terminal |
| nvm | Formula | Node.js version manager |
| opentofu | Formula | Open-source Terraform alternative |
| podman | Formula | Daemonless container runtime (Docker alternative) |
| podman-compose | Formula | Docker Compose equivalent for Podman |
| uv | Formula | Ultra-fast Python package installer and resolver |
| ykman | Formula | YubiKey Manager CLI for configuring YubiKey devices |
| anydesk | Cask | Remote desktop |
| audacity | Cask | Audio editor |
| bitwarden | Cask | Password manager |
| codelayer | Cask | Code overlay tool for screen recordings and presentations |
| dropbox | Cask | Cloud storage |
| gcloud-cli | Cask | Google Cloud CLI |
| github | Cask | GitHub Desktop |
| google-drive | Cask | Google Drive sync client |
| inkscape | Cask | Vector graphics editor |
| logi-options+ | Cask | Logitech device configuration |
| postman | Cask | API testing tool |
| spotify | Cask | Music streaming |
| stremio | Cask | Media centre |
| tailscale-app | Cask | Mesh VPN |
| transmission | Cask | BitTorrent client |
| vlc | Cask | Media player |
| wireshark | Cask | Network protocol analyser |
| yubico-authenticator | Cask | TOTP authenticator that stores codes on a YubiKey |

### Work Packages (opt-in)

These are **excluded by default**. To include them, edit `macos/new-mac.sh` and add `"${work_packages[@]}"` to the `all_packages` array:

| Package | Type |
|---------|------|
| slack | Cask |
| microsoft-teams | Cask |
| terraform | Formula |

### Mac App Store

Installed via `mas` (requires App Store sign-in):

| App | App Store ID |
|-----|-------------|
| Magnet (window manager) | 441258766 |

## What Gets Configured

| Category | What the script does | Source file(s) |
|----------|---------------------|----------------|
| Dock | Removes all items, adds 16 apps + 2 spacers + Downloads folder; sets auto-hide, magnification, tile size 44, hides recents | `macos/new-mac.sh` |
| System preferences | Hot corner (BR → Quick Note), accent colour (Pink), highlight colour (Green), Mission Control (group by app, no auto-rearrange), Finder (column view) | `macos/new-mac.sh` |
| Power | AC: display and system sleep disabled; battery: display sleep 10 min, system sleep 1 min | `macos/new-mac.sh` |
| Default browser | Brave Browser set as default for HTTP/HTTPS via Swift/NSWorkspace API | `macos/new-mac.sh` |
| Login items | Caffeine, noTunes, Magnet, Bluesnooze, Google Drive, Raycast added via AppleScript | `macos/new-mac.sh` |
| Shell | Oh My Zsh with zsh-autosuggestions plugin; random theme from curated list; aliases (docker→podman, terraform shortcuts, git helpers) | `macos/zshrc`, `macos/aliases.zsh` |
| Git | `.gitconfig` with user identity, SSH key path, `push.autoSetupRemote`, `pull.rebase`, conditional includes for org-specific configs | `macos/new-mac.sh` |
| Vim | `.vimrc` with line numbers, search highlighting, tab/space settings, cursor line highlighting | `macos/vimrc` |
| Repositories | Clones `workscripts`, `rune`, `orbit`, `agentic-coding` into `~/repos/` | `macos/new-mac.sh` |
| Go tools | Installs `rune` and `orbit` via `make install` or `go install` | `macos/new-mac.sh` |
| Claude Code | Symlinks `~/.claude/skills` → `~/repos/agentic-coding/claude/skills` | `macos/new-mac.sh` |
| iTerm2 | Imports preferences from plist file | `macos/iterm2-prefs.plist` |
| Containers | Podman and podman-compose installed (install-only — no machine init); reference compose file available | `macos/docker-compose.yml` |

## Post-Setup Manual Steps

After the script completes, restart your terminal (or run `source ~/.zshrc`) to pick up all shell changes. Then work through these items:

### App Store and Licensing

- [ ] **App Store sign-in** — if not already signed in, open the App Store and sign in so that `mas`-installed apps (Magnet) activate correctly
- [ ] **Magnet license** — open Magnet, enter your license key to unlock full functionality

### App Logins

Sign into each of these apps with your existing accounts:

- [ ] **NordVPN** — open and log in
- [ ] **Bitwarden** — open and log in to your vault
- [ ] **Tailscale** — open and authenticate with your tailnet
- [ ] **Dropbox** — open and sign in to start syncing
- [ ] **Spotify** — open and log in
- [ ] **Google Drive** — open and sign in to start syncing

### Configuration Syncs

- [ ] **VS Code Settings Sync** — open VS Code, sign in with your GitHub account, and enable Settings Sync to restore extensions, keybindings, and preferences
- [ ] **Raycast** — open Raycast, configure your preferred extensions, hotkeys, and clipboard history settings
- [ ] **Logi Options+** — open Logi Options+ and pair your Logitech devices (mouse, keyboard) to restore button mappings and scroll settings

### Git Configuration

- [ ] **Edit `.gitconfig` conditional includes** — the generated `~/.gitconfig` contains placeholder `includeIf` entries for `SPECIFIC_FOLDER` and `another_specific_folder`. Update these paths and config file references to match your actual org-specific Git configurations:

  ```ini
  [includeIf "gitdir:~/Repos/SPECIFIC_FOLDER/"]
      path = ~/.gc/specific_config_file
  ```

### Optional

- [ ] **Install full Xcode** — if you need `Simulator.app` (included in the Dock layout), install Xcode from the App Store. The setup script only installs Xcode Command Line Tools

## Verification

After setup completes (and after restarting your terminal), run the verification script from the repo root:

```bash
cd ~/repos/workscripts
bash macos/verify-setup.sh
```

The script checks ~30 items across these categories:

- **Dock Apps** — verifies each expected app is in the Dock
- **Dock Preferences** — confirms auto-hide, tile size, magnification, and recents settings
- **System Preferences** — checks hot corner, accent colour, Mission Control, and Finder view
- **Power Management** — validates AC and battery sleep settings
- **Default Browser** — confirms Brave is the default for HTTP/HTTPS
- **Login Items** — checks that Caffeine, noTunes, Magnet, Bluesnooze, Google Drive, and Raycast are registered
- **Homebrew Packages** — spot-checks a sample of installed packages (bat, fzf, tmux, mas, dockutil)
- **Shell Config** — verifies `aliases.zsh` exists, is sourced, and docker/podman aliases are defined
- **Compose File** — confirms `docker-compose.yml` exists in the repo

Each check shows ✅ (pass) or ❌ (fail). The final line reports totals, e.g. `Results: 28 passed, 2 failed`. Investigate any failures — they usually indicate an app wasn't installed or a preference didn't persist (a restart or re-run may fix it).

## Customisation Points

To tailor the setup for your own use, edit these in `macos/new-mac.sh`:

- **`default_packages` / `home_packages` arrays** (lines ~133–153) — add or remove Homebrew formulae and casks
- **`work_packages` array** (line ~142) — add packages you only need for work; include `"${work_packages[@]}"` in the `all_packages` line to opt in
- **`DOCK_NAMES` / `DOCK_PATHS` arrays** (lines ~234–258) — change the Dock app order, add/remove apps, or insert `"SPACER"` entries
- **`LOGIN_APPS` array** (lines ~371–378) — control which apps launch at login
- **`clone_repo` calls** (lines ~494–497) — add or remove repositories cloned into `~/repos/`

## Troubleshooting

**Homebrew PATH on Apple Silicon**
Homebrew installs to `/opt/homebrew` on Apple Silicon Macs. If `brew` isn't found after installation, add this to your `~/.zshrc` (the setup script does this automatically, but if you're debugging a partial run):

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**`mas` requires App Store sign-in**
The `mas` CLI can only install apps if you're signed into the App Store with your Apple ID. If Magnet fails to install, open the App Store, sign in, and re-run `mas install 441258766`.

**SSH key already exists**
If `~/.ssh/github` already exists, the script skips key generation and prints `✅ SSH key already exists at ~/.ssh/github`. This is safe — the existing key is preserved. If you need to regenerate, remove the old key first: `rm ~/.ssh/github ~/.ssh/github.pub`.

**`~/SETUP.log` for debugging**
All output from the unattended phase is appended to `~/SETUP.log`. If the script completes but something seems wrong, check this file for errors:

```bash
cat ~/SETUP.log | grep -i "fail\|error\|⚠️"
```
