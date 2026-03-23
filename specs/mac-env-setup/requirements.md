# Requirements — mac-env-setup (v2)

## Introduction

Enhance `macos/new-mac.sh` and supporting configuration to provide a **complete, reproducible macOS environment** that mirrors the current user setup. The script should be structured in two phases:

1. **Interactive phase** — Collect user input (name, email), set up SSH keys and GitHub authentication, and collect sudo credentials. This phase requires the user to be present.
2. **Unattended phase** — Install packages, configure system preferences, set up the Dock, deploy shell configs, clone repos, and install tools. This phase should run without user interaction, using elevated access (sudo) where required.

**Tool dependencies:** `dockutil` (Dock manipulation), `mas` (Mac App Store apps)
**Execution order:** Interactive setup → Homebrew packages → Shell config → System preferences → Dock → Power management → Login items → Default browser → Developer setup → Summary
**Error strategy:** All new sections are non-critical and use `|| true` guards to avoid `set -e` termination.

---

### 1. Dock Configuration — Complete App Layout

**User Story:** As a developer setting up a new Mac, I want the Dock to exactly replicate my current layout including spacers, so that I have my familiar workspace immediately.

**Acceptance Criteria:**

1. <a name="1.1"></a>The `default_packages` array SHALL include `dockutil` as a prerequisite for Dock manipulation
2. <a name="1.2"></a>The script SHALL use `dockutil --remove all --no-restart` to remove all existing persistent apps from the macOS Dock (Finder is preserved automatically by macOS)
3. <a name="1.3"></a>The script SHALL add the following apps to the Dock in this exact order:
   1. iTerm (`/Applications/iTerm.app`)
   2. Notes (`/System/Applications/Notes.app`)
   3. **Spacer tile**
   4. WhatsApp (`/Applications/WhatsApp.app`)
   5. **Spacer tile**
   6. Transmission (`/Applications/Transmission.app`)
   7. VLC (`/Applications/VLC.app`)
   8. Calendar (`/System/Applications/Calendar.app`)
   9. System Settings (`/System/Applications/System Settings.app`)
   10. Stremio (`/Applications/Stremio.app`)
   11. TV (`/System/Applications/TV.app`)
   12. Brave Browser (`/Applications/Brave Browser.app`)
   13. iPhone Mirroring (`/System/Applications/iPhone Mirroring.app`)
   14. Audacity (`/Applications/Audacity.app`)
   15. Visual Studio Code (`/Applications/Visual Studio Code.app`)
   16. Simulator (`/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app`)
4. <a name="1.4"></a>The script SHALL add spacer tiles using `dockutil --add '' --type spacer --no-restart` at positions 3 and 5 (after Notes and after WhatsApp)
5. <a name="1.5"></a>The script SHALL add a Downloads folder to the Dock's persistent-others section using `dockutil --add ~/Downloads --section others --no-restart`
6. <a name="1.6"></a>The script SHALL verify each app exists at its path before adding it to the Dock, and log a warning if the app is not found
7. <a name="1.7"></a>The script SHALL restart the Dock process (`killall Dock`) after applying all changes
8. <a name="1.8"></a>WHEN the script is re-run on an already-configured Mac, THEN it SHALL produce the same Dock state without errors

---

### 2. Dock Configuration — Preferences

**User Story:** As a developer, I want my Dock sized, positioned, and behaving the way I prefer, without manual configuration.

**Acceptance Criteria:**

1. <a name="2.1"></a>The script SHALL set `show-recents` to `false` in the `com.apple.dock` domain via `defaults write`
2. <a name="2.2"></a>The script SHALL set `tilesize` to `44` in `com.apple.dock`
3. <a name="2.3"></a>The script SHALL enable magnification (`magnification -bool true`) and set `largesize` to `128` in `com.apple.dock`
4. <a name="2.4"></a>The script SHALL enable auto-hide (`autohide -bool true`) in `com.apple.dock`
5. <a name="2.5"></a>WHEN the Dock is restarted after these changes, THEN all settings SHALL be applied

---

### 3. Homebrew Package List — Complete Reconciliation

**User Story:** As a developer setting up a new Mac, I want all my tools and applications installed automatically, so that I don't need to install anything manually after setup.

**Acceptance Criteria:**

1. <a name="3.1"></a>The `default_packages` array SHALL include the following **formulae**: `bat`, `fzf`, `gh`, `git`, `htop`, `jq`, `rename`, `tmux`, `tree`, `wget`, `yq`, `go`, `dockutil`
2. <a name="3.2"></a>The `default_packages` array SHALL include the following **casks**: `bluesnooze`, `brave-browser`, `caffeine`, `claude-code`, `firefox`, `gimp`, `google-chrome`, `iterm2`, `nordvpn`, `notunes`, `raycast`, `visual-studio-code`, `whatsapp`
3. <a name="3.3"></a>The `home_packages` array SHALL include the following **formulae**: `awscli`, `azure-cli`, `cloudflared`, `lychee`, `mas`, `nvm`, `opentofu`, `podman`, `podman-compose`, `uv`, `ykman`
4. <a name="3.4"></a>The `home_packages` array SHALL include the following **casks**: `anydesk`, `audacity`, `bitwarden`, `codelayer`, `dropbox`, `gcloud-cli`, `github`, `google-drive`, `inkscape`, `logi-options+`, `postman`, `spotify`, `stremio`, `tailscale-app`, `transmission`, `vlc`, `wireshark`, `yubico-authenticator`
5. <a name="3.5"></a>The script SHALL install Magnet from the Mac App Store using `mas install 441258766` after Homebrew packages are installed (requires prior App Store authentication)
6. <a name="3.6"></a>The existing Homebrew install flow SHALL install all packages without additional user interaction
7. <a name="3.7"></a>The `work_packages` array SHALL remain separate and only be installed when explicitly selected by the user

---

### 4. Default Browser

**User Story:** As a developer, I want Brave Browser set as my default browser automatically, so I don't need to configure it manually in System Settings.

**Acceptance Criteria:**

1. <a name="4.1"></a>The script SHALL set Brave Browser as the default browser using a Swift one-liner that calls `NSWorkspace.shared.setDefaultApplication(at:toOpenURLsWithScheme:)` for both `http` and `https` schemes with bundle identifier `com.brave.Browser`
2. <a name="4.2"></a>The script SHALL use AppleScript to automatically dismiss the macOS confirmation dialog that appears when changing the default browser
3. <a name="4.3"></a>IF Brave Browser is not installed, THEN the script SHALL log a warning and skip
4. <a name="4.4"></a>This approach requires no additional Homebrew packages — it uses built-in macOS frameworks (AppKit/NSWorkspace, available on macOS 12+)

---

### 5. System Preferences

**User Story:** As a developer, I want my preferred system settings applied automatically, so that macOS behaves the way I expect from the moment setup completes.

**Acceptance Criteria:**

1. <a name="5.1"></a>The script SHALL set the bottom-right hot corner to Quick Note (value `14`) via `defaults write com.apple.dock wvous-br-corner -int 14` and `defaults write com.apple.dock wvous-br-modifier -int 0`
2. <a name="5.2"></a>The script SHALL set the accent color to Pink (value `6`) via `defaults write NSGlobalDomain AppleAccentColor -int 6`
3. <a name="5.3"></a>The script SHALL set the highlight color to Green via `defaults write NSGlobalDomain AppleHighlightColor -string "0.752941 0.964706 0.678431 Green"`
4. <a name="5.4"></a>The script SHALL configure Mission Control: group windows by application (`expose-group-apps -bool true`) and disable auto-rearrange spaces (`mru-spaces -bool false`)
5. <a name="5.5"></a>The script SHALL set Finder default view to Column view via `defaults write com.apple.finder FXPreferredViewStyle -string "clmv"`
6. <a name="5.6"></a>The script SHALL restart Finder after preference changes (`killall Finder || true`)

---

### 6. Power & Sleep Management

**User Story:** As a developer, I want my Mac to never sleep when plugged in, so that long-running tasks aren't interrupted.

**Acceptance Criteria:**

1. <a name="6.1"></a>The script SHALL set AC power display sleep to 0 (never) via `sudo pmset -c displaysleep 0`
2. <a name="6.2"></a>The script SHALL set AC power system sleep to 0 (never) via `sudo pmset -c sleep 0`
3. <a name="6.3"></a>The script SHALL set Battery display sleep to 10 minutes via `sudo pmset -b displaysleep 10`
4. <a name="6.4"></a>The script SHALL set Battery system sleep to 1 minute via `sudo pmset -b sleep 1`
5. <a name="6.5"></a>The `sudo` password SHALL be collected once during the interactive phase and cached for the duration of the script via `sudo -v` with a keep-alive loop

---

### 7. Login Items

**User Story:** As a developer, I want my preferred apps to launch at login, so that my utilities are always running.

**Acceptance Criteria:**

1. <a name="7.1"></a>The script SHALL add the following apps as login items: Caffeine, noTunes, Magnet, Bluesnooze, Google Drive, Raycast
2. <a name="7.2"></a>The script SHALL use `osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/AppName.app", hidden:false}'` to add login items
3. <a name="7.3"></a>The script SHALL check if each login item already exists before adding to ensure idempotency
4. <a name="7.4"></a>IF an app is not installed, THEN the script SHALL skip adding it as a login item and log a warning

---

### 8. Podman Compose File

*Retained from v1 — no changes*

**User Story:** As a developer, I want a reference docker-compose.yml file for local container-based development.

**Acceptance Criteria:**

1. <a name="8.1"></a>A `macos/docker-compose.yml` file SHALL exist in the repository
2. <a name="8.2"></a>The compose file SHALL define a PostgreSQL service with a named volume for data persistence
3. <a name="8.3"></a>The compose file SHALL define a placeholder app service on the same network as the database
4. <a name="8.4"></a>The services SHALL be on a shared network with DNS enabled for container name resolution
5. <a name="8.5"></a>The compose file SHALL use environment variables for configurable values
6. <a name="8.6"></a>The setup script SHALL NOT run `podman machine init`, `podman machine start`, or any containers

---

### 9. Docker-Compatible Aliases

*Retained from v1 — no changes*

**User Story:** As a developer transitioning from Docker to Podman, I want `docker` and `docker-compose` commands to transparently invoke Podman.

**Acceptance Criteria:**

1. <a name="9.1"></a>The `aliases.zsh` file SHALL define `alias docker='podman'`
2. <a name="9.2"></a>The `aliases.zsh` file SHALL define `alias docker-compose='podman-compose'`
3. <a name="9.3"></a>The existing `dockernuke` alias SHALL be updated to use `podman` commands
4. <a name="9.4"></a>The existing `dockerclear` alias SHALL be updated to use `podman` commands

---

### 10. Shell Configuration Deployment

*Retained from v1 — no changes*

**User Story:** As a developer, I want my shell aliases deployed automatically.

**Acceptance Criteria:**

1. <a name="10.1"></a>The setup script SHALL download `aliases.zsh` from the repository to `~/.aliases.zsh`
2. <a name="10.2"></a>The `zshrc` template SHALL include a `source ~/.aliases.zsh` line (with existence check)
3. <a name="10.3"></a>WHEN the script is re-run, THEN it SHALL overwrite the aliases file with the latest version
4. <a name="10.4"></a>IF `aliases.zsh` cannot be downloaded, THEN the script SHALL log a warning and continue

---

### 11. Idempotency and Error Handling

*Updated from v1 to cover all new sections*

**User Story:** As a developer, I want the setup script to be safe to re-run at any time.

**Acceptance Criteria:**

1. <a name="11.1"></a>Every section in `new-mac.sh` SHALL check for existing state before making changes
2. <a name="11.2"></a>WHEN a non-critical operation fails, THEN the script SHALL use `|| true` or subshell guards to log and continue
3. <a name="11.3"></a>All operations SHALL be logged to `~/SETUP.log`
4. <a name="11.4"></a>The script SHALL collect `sudo` credentials early and maintain them via a background keep-alive process (`while true; do sudo -n true; sleep 60; done &`)
5. <a name="11.5"></a>The script SHALL be structured with a clear interactive phase (requiring user presence) followed by an unattended phase (no further input needed)

---

### 12. App-Level Settings (Stretch Goal)

**User Story:** As a developer, I want my app-level preferences (iTerm2 profiles, Magnet shortcuts) restored automatically.

**Acceptance Criteria:**

1. <a name="12.1"></a>The script SHOULD export and import iTerm2 preferences via `defaults export com.googlecode.iterm2 ~/iterm2-prefs.plist` / `defaults import`
2. <a name="12.2"></a>IF an app's settings cannot be programmatically restored, THEN the limitation SHALL be documented in the spec with the reason
3. <a name="12.3"></a>This section is a stretch goal — implementation is optional and should not block the core feature

---

### Known Limitations

- **Mac App Store authentication**: `mas install` requires the user to be signed into the App Store. If not signed in, the script should warn and continue.
- **Login items**: macOS Ventura+ changed how login items work. The `osascript` approach may require user approval in System Settings > General > Login Items.
- **Default browser confirmation dialog**: macOS always shows a confirmation dialog when changing the default browser. The script uses AppleScript to auto-dismiss it, but this relies on the dialog's UI structure which may change between macOS versions.
- **Simulator.app**: Only available if full Xcode is installed. The script installs Xcode CLI tools but the full Xcode.app (and thus Simulator) may need to be installed separately via the App Store.
