---
references:
    - specs/mac-env-setup/requirements.md
    - specs/mac-env-setup/design.md
    - specs/mac-env-setup/decision_log.md
---
# mac-env-setup (v2)

## Phase A: Script Restructuring

- [x] 1. Restructure new-mac.sh into interactive and unattended phases <!-- id:1a0001 -->
  - Stream: 1
  - Requirements: [11.5](requirements.md#11.5)
  - [x] 1.1. Move user input collection (name, email prompts) from line 154 to immediately after Homebrew install (before packages)
  - [x] 1.2. Move SSH key setup section to immediately after user input collection
  - [x] 1.3. Add `sudo -v` prompt and background keep-alive loop (`while true; do sudo -n true; sleep 60; done &`) after SSH setup
  - [x] 1.4. Store keep-alive PID in `SUDO_KEEPALIVE_PID` and add `trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null' EXIT`
  - [x] 1.5. Add "walk away" banner: `echo "🚀 Unattended phase starting — you can walk away now"`
  - [x] 1.6. Kill `SUDO_KEEPALIVE_PID` in the summary section before final output

## Phase B: Package Management

- [x] 2. Update Homebrew package arrays to match current environment <!-- id:1a0002 -->
  - Stream: 1
  - Requirements: [3.1](requirements.md#3.1), [3.2](requirements.md#3.2), [3.3](requirements.md#3.3), [3.4](requirements.md#3.4), [3.6](requirements.md#3.6), [3.7](requirements.md#3.7)
  - [x] 2.1. Replace `default_packages` array with: `bat`, `fzf`, `gh`, `git`, `htop`, `jq`, `rename`, `tmux`, `tree`, `wget`, `yq`, `go`, `bluesnooze`, `brave-browser`, `caffeine`, `claude-code`, `dockutil`, `firefox`, `gimp`, `google-chrome`, `iterm2`, `nordvpn`, `notunes`, `raycast`, `visual-studio-code`, `whatsapp`
  - [x] 2.2. Replace `home_packages` array with: `awscli`, `azure-cli`, `cloudflared`, `lychee`, `mas`, `nvm`, `opentofu`, `podman`, `podman-compose`, `uv`, `ykman`, `anydesk`, `audacity`, `bitwarden`, `codelayer`, `dropbox`, `gcloud-cli`, `github`, `google-drive`, `inkscape`, `logi-options+`, `postman`, `spotify`, `stremio`, `tailscale-app`, `transmission`, `vlc`, `wireshark`, `yubico-authenticator`
  - [x] 2.3. Keep `work_packages` unchanged and ensure it is NOT included in `all_packages`
  - [x] 2.4. Add inline comments grouping formulae and casks within each array

- [x] 3. Add Mac App Store installation section <!-- id:1a0003 -->
  - Blocked-by: 1a0002
  - Stream: 1
  - Requirements: [3.5](requirements.md#3.5)
  - [x] 3.1. Add section after `brew install` that checks `command -v mas`
  - [x] 3.2. Check if Magnet already installed via `mas list | grep -q "441258766"`
  - [x] 3.3. Run `mas install 441258766` with `|| echo` guard and App Store sign-in warning

## Phase C: System Configuration

- [x] 4. Add system preferences section <!-- id:1a0004 -->
  - Blocked-by: 1a0001
  - Stream: 2
  - Requirements: [5.1](requirements.md#5.1), [5.2](requirements.md#5.2), [5.3](requirements.md#5.3), [5.4](requirements.md#5.4), [5.5](requirements.md#5.5), [5.6](requirements.md#5.6)
  - [x] 4.1. Add `defaults write com.apple.dock wvous-br-corner -int 14` and `wvous-br-modifier -int 0`
  - [x] 4.2. Add `defaults write NSGlobalDomain AppleAccentColor -int 6`
  - [x] 4.3. Add `defaults write NSGlobalDomain AppleHighlightColor -string "0.752941 0.964706 0.678431 Green"`
  - [x] 4.4. Add `defaults write com.apple.dock expose-group-apps -bool true` and `mru-spaces -bool false`
  - [x] 4.5. Add `defaults write com.apple.finder FXPreferredViewStyle -string "clmv"`
  - [x] 4.6. Add `killall Finder || true`

- [x] 5. Update Dock configuration with full app layout, spacers, and preferences <!-- id:1a0005 -->
  - Blocked-by: 1a0001
  - Stream: 2
  - Requirements: [1.2](requirements.md#1.2), [1.3](requirements.md#1.3), [1.4](requirements.md#1.4), [1.5](requirements.md#1.5), [1.6](requirements.md#1.6), [1.7](requirements.md#1.7), [1.8](requirements.md#1.8), [2.1](requirements.md#2.1), [2.2](requirements.md#2.2), [2.3](requirements.md#2.3), [2.4](requirements.md#2.4), [2.5](requirements.md#2.5)
  - [x] 5.1. Replace `DOCK_NAMES` and `DOCK_PATHS` arrays with full 16-app list including `SPACER` sentinel entries at positions 3 and 5
  - [x] 5.2. Update loop to handle `SPACER` entries: `dockutil --add '' --type spacer --section apps --no-restart`
  - [x] 5.3. Add `dockutil --add "$HOME/Downloads" --section others --no-restart` after app loop
  - [x] 5.4. Add Dock preference writes: `tilesize -int 44`, `magnification -bool true`, `largesize -int 128`, `autohide -bool true`
  - [x] 5.5. Ensure `killall Dock` remains as the final step after all Dock changes

- [x] 6. Add power management section <!-- id:1a0006 -->
  - Blocked-by: 1a0001
  - Stream: 2
  - Requirements: [6.1](requirements.md#6.1), [6.2](requirements.md#6.2), [6.3](requirements.md#6.3), [6.4](requirements.md#6.4)
  - [x] 6.1. Add `sudo pmset -c displaysleep 0` and `sudo pmset -c sleep 0` with `|| echo` guards
  - [x] 6.2. Add `sudo pmset -b displaysleep 10` and `sudo pmset -b sleep 1` with `|| echo` guards

- [x] 7. Add default browser section <!-- id:1a0007 -->
  - Blocked-by: 1a0002
  - Stream: 2
  - Requirements: [4.1](requirements.md#4.1), [4.2](requirements.md#4.2), [4.3](requirements.md#4.3), [4.4](requirements.md#4.4)
  - [x] 7.1. Add `[ -d "/Applications/Brave Browser.app" ]` guard
  - [x] 7.2. Add background AppleScript to auto-dismiss CoreServicesUIAgent confirmation dialog
  - [x] 7.3. Add Swift heredoc using `NSWorkspace.shared.setDefaultApplication(at:toOpenURLsWithScheme:)` for `http` and `https` with bundle ID `com.brave.Browser`
  - [x] 7.4. Add cleanup: `kill $DIALOG_PID` and `wait`

- [x] 8. Add login items section <!-- id:1a0008 -->
  - Blocked-by: 1a0002
  - Stream: 2
  - Requirements: [7.1](requirements.md#7.1), [7.2](requirements.md#7.2), [7.3](requirements.md#7.3), [7.4](requirements.md#7.4)
  - [x] 8.1. Define `LOGIN_APPS` array with paths to Caffeine, noTunes, Magnet, Bluesnooze, Google Drive, Raycast
  - [x] 8.2. Query current login items once via `osascript` and cache result
  - [x] 8.3. Loop: check app exists (`[ -d ]`), check not already in login items (`grep -qi`), add via `osascript` with `|| echo` guard

## Phase D: Verification & Documentation

- [ ] 9. Update verify-setup.sh with all new checks <!-- id:1a0009 -->
  - Blocked-by: 1a0004, 1a0005, 1a0006, 1a0007, 1a0008
  - Stream: 1
  - Requirements: [11.1](requirements.md#11.1)
  - [ ] 9.1. Add Dock app checks for all 16 apps via `dockutil --find`
  - [ ] 9.2. Add Dock preference checks: tilesize, magnification, largesize, autohide, show-recents
  - [ ] 9.3. Add system preference checks: hot corner, accent color, Mission Control, Finder view
  - [ ] 9.4. Add power management checks via `pmset -g custom` parsing
  - [ ] 9.5. Add default browser check via LaunchServices plist
  - [ ] 9.6. Add login items checks via `osascript` query
  - [ ] 9.7. Add expanded Homebrew package spot-checks (bat, fzf, tmux, mas, dockutil)

- [ ] 10. Update decision_log.md with new design decisions <!-- id:1a0010 -->
  - Stream: 1
  - [ ] 10.1. Add D23: Script restructuring into interactive/unattended phases
  - [ ] 10.2. Add D24: Sudo keep-alive mechanism
  - [ ] 10.3. Add D25: Default browser via Swift/NSWorkspace (replacing defaultbrowser CLI)
  - [ ] 10.4. Add D26: Full Dock layout with SPACER sentinel pattern
  - [ ] 10.5. Add D27: Login items via osascript
  - [ ] 10.6. Add D28: Power management values (AC: never, Battery: 10/1)
  - [ ] 10.7. Add D29: Scoped out items (VS Code extensions, wallpaper, computer name) with rationale
  - [ ] 10.8. Add D30: Mac App Store via mas for Magnet only

## Phase E: Stretch Goal

- [ ] 11. Add iTerm2 preferences import (stretch) <!-- id:1a0011 -->
  - Blocked-by: 1a0005
  - Stream: 3
  - Requirements: [12.1](requirements.md#12.1), [12.2](requirements.md#12.2), [12.3](requirements.md#12.3)
  - [ ] 11.1. Export current iTerm2 preferences: `defaults export com.googlecode.iterm2 macos/iterm2-prefs.plist` and commit to repo
  - [ ] 11.2. Add import section in new-mac.sh: check plist exists and iTerm2 installed, then `defaults import com.googlecode.iterm2 macos/iterm2-prefs.plist`
  - [ ] 11.3. Document limitations for apps that cannot be automated (Magnet license, Raycast, NordVPN, Bitwarden) in decision_log.md
