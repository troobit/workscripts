# Decision Log — mac-env-setup

## D1: Feature name
- **Decision:** `mac-env-setup`
- **Rationale:** Covers dock customization, podman container setup, and app management holistically

## D2: Dock app list
- **Decision:** Dock will contain only: Finder, Brave Browser, WhatsApp, iTerm2, Calendar
- **Rationale:** User-specified minimal dock. All other defaults removed. Recent apps section disabled.

## D3: Brave Browser and WhatsApp
- **Decision:** Add `brave-browser` and `whatsapp` to `default_packages` in brew install list
- **Rationale:** Both needed in the Dock, so they must be installed by the script

## D4: Proxy configuration
- **Decision:** General networking only (no corporate proxy config)
- **Rationale:** Containers just need standard inter-container and host communication with internet access

## D5: Podman volumes
- **Decision:** Mount local project directories (e.g., ~/repos) into containers
- **Rationale:** Primary use case is local development, not persistent named volumes for databases

## D6: Docker alias strategy
- **Decision:** Replace existing docker aliases with podman equivalents; alias `docker`→`podman` and `docker-compose`→`podman-compose`
- **Rationale:** Single container runtime, avoid confusion between docker and podman commands

## D7: Backwards compatibility
- **Decision:** All new sections must be idempotent (safe to re-run)
- **Rationale:** Matches existing script pattern — check state before modifying

## D8: Recent apps in Dock
- **Decision:** Disable "Show recent applications in Dock" via `defaults write`
- **Rationale:** User explicitly requested this

## D9: Dock manipulation tool
- **Decision:** Use `dockutil` (installed via Homebrew) for Dock manipulation
- **Rationale:** macOS has no built-in CLI for adding/removing Dock items. `dockutil` is the standard third-party tool. Added to `default_packages`.

## D10: Finder in Dock list
- **Decision:** Exclude Finder from the explicit add list; macOS preserves it automatically
- **Rationale:** Finder cannot be removed from the Dock via `dockutil`; listing it would be redundant

## D11: set -e conflict resolution
- **Decision:** Non-critical sections use `|| true` guards; critical sections exit on failure
- **Rationale:** Existing script uses `set -e`. Rather than removing it (which would weaken error handling for existing sections), wrap non-critical new sections.

## D12: Podman default home mount
- **Decision:** Rely on Podman 4+ default home directory mount for ~/repos access
- **Rationale:** Podman on macOS mounts the user home by default. No need for explicit `--volume` flag on `podman machine init`.

## D13: docker-compose compatibility scope
- **Decision:** Aliases support common Compose features; full compatibility is not guaranteed
- **Rationale:** `podman-compose` has known incompatibilities with advanced docker-compose features (depends_on conditions, some network modes)

## D14: dockutil v3 syntax
- **Decision:** Use `--no-restart` flag to batch changes, single `killall Dock` at end
- **Rationale:** Research confirmed `--no-restart` IS supported in dockutil v3.1.3 (current Homebrew version). README documents it explicitly. Batching avoids multiple Dock restarts.

## D15: Shell config deployment (aliases.zsh only)
- **Decision:** Download `aliases.zsh` from the repo and source it from `~/.zshrc`. Remove `path.zsh` from the repo.
- **Rationale:** `aliases.zsh` was never deployed or sourced — without this, alias changes (section 7) would never take effect. `path.zsh` is redundant (see D16).

## D16: Remove path.zsh
- **Decision:** Remove `macos/path.zsh` from the repository
- **Rationale:** pnpm PATH is handled automatically by `brew install pnpm`. NVM manages its own PATH via its installer. Homebrew PATH is already set by `eval "$(/opt/homebrew/bin/brew shellenv)"` in the script. The file also contained a hardcoded `/Users/ronan/Library/pnpm` path that wouldn't work on other users' machines.

## D17: Homebrew bash re-exec — SUPERSEDED by D19
- **Decision:** ~~Re-exec script under Homebrew's bash 4+~~ → Replaced with indexed arrays
- **Rationale:** See D19

## D18: Drop NVM
- **Decision:** NVM is not installed or configured by the setup script
- **Rationale:** NVM init was only in `path.zsh` which is being removed. NVM is not in the Homebrew package list and is not needed for the current development workflow.

## D19: Use indexed arrays instead of associative arrays
- **Decision:** Use two parallel indexed arrays (`DOCK_NAMES`, `DOCK_PATHS`) instead of `declare -A`
- **Rationale:** Eliminates need for bash 4+ and the entire re-exec component. macOS ships bash 3.2 which supports indexed arrays but not associative arrays. Two reviewers independently recommended this simplification.

## D20: Podman network DNS default — SUPERSEDED by D21
- **Decision:** ~~Omit `--dns-enabled` flag~~ → No network creation in script at all
- **Rationale:** See D21

## D21: Podman is install-only
- **Decision:** The setup script installs Podman and podman-compose via Homebrew but does NOT initialise/start the machine, create networks, or run containers
- **Rationale:** User feedback: Podman just needs to be available. Machine init, networking, and containers are user-initiated via the reference compose file. This keeps the setup script simple and avoids side effects.

## D22: Compose file volume separation
- **Decision:** Compose file mounts `./src` (project subdirectory) not `~/repos` directly
- **Rationale:** User specified that network drives should not be mapped to ~/repos but rather a subdirectory. Each project gets its own compose file with its own mount context.

---

## v2 Decisions

## D23: Script restructuring — interactive/unattended phases
- **Decision:** Restructure `new-mac.sh` into two distinct phases: interactive (Xcode, Homebrew install, user input, SSH keys, sudo credentials) followed by unattended (everything else)
- **Rationale:** User wants to log in, answer a few prompts, then walk away. Moving all interactive steps before package installation creates a clean boundary. A "walk away" banner marks the transition.

## D24: Sudo keep-alive mechanism
- **Decision:** Use `sudo -v` during interactive phase with a background `while true; do sudo -n true; sleep 60; done` keep-alive loop, killed on script exit via `trap EXIT`
- **Rationale:** `pmset` requires `sudo`. Without keep-alive, the sudo credential cache (default 5 minutes) would expire during long package installs, causing the power management section to fail or prompt mid-unattended phase.

## D25: Default browser via Swift/NSWorkspace — replacing defaultbrowser CLI
- **Decision:** Set Brave as default browser using a Swift heredoc that calls `NSWorkspace.shared.setDefaultApplication(at:toOpenURLsWithScheme:)` for `http` and `https`. Use background AppleScript to auto-dismiss the system confirmation dialog.
- **Rationale:** The `defaultbrowser` CLI (kerma/defaultbrowser) is being deprecated. Swift/NSWorkspace is built into macOS 12+ (no extra dependency), uses the modern API (`LSSetDefaultHandlerForURLScheme` was removed in macOS 12), and Swift is available after Xcode CLI tools are installed.

## D26: Full Dock layout with SPACER sentinel pattern
- **Decision:** Expand Dock from 4 apps to 16 apps + 2 spacers + Downloads folder. Use `SPACER` as a sentinel value in `DOCK_NAMES` array to trigger `dockutil --add '' --type spacer` during the loop.
- **Rationale:** The current 4-app Dock doesn't match the user's actual 16-app layout. The SPACER sentinel keeps the single-loop pattern (bash 3.2 compatible) and avoids post-loop position-based insertion which would be fragile.

## D27: Login items via osascript
- **Decision:** Use `osascript -e 'tell application "System Events" to make login item at end with properties {path:"...", hidden:false}'` to add login items. Check existing items via `osascript` query before adding.
- **Rationale:** AppleScript is the supported way to manage login items programmatically. macOS Ventura+ may show a notification, but this is unavoidable — documented as a known limitation.

## D28: Power management values
- **Decision:** AC: displaysleep=0, sleep=0 (never). Battery: displaysleep=10, sleep=1.
- **Rationale:** Captured from current environment via `pmset -g custom`. AC never-sleep prevents long-running tasks from being interrupted. Battery values are conservative for portable use.

## D29: Scoped out items
- **Decision:** VS Code extensions, desktop wallpaper, and computer name are out of scope.
- **Rationale:** VS Code extensions are managed by the logged-in user (Settings Sync). Desktop wallpaper/background and data collection are out of scope per user decision. Computer name prompt is out of scope.

## D30: Mac App Store via mas — Magnet only
- **Decision:** Install `mas` via Homebrew, use `mas install 441258766` for Magnet. No other App Store apps needed.
- **Rationale:** Magnet is the only currently-installed app that is only available via the Mac App Store. All other apps are available via Homebrew casks. `mas` requires prior App Store authentication — script warns and continues if not signed in.

## D18: Drop NVM — SUPERSEDED
- **Decision:** ~~NVM is not installed by the setup script~~ → NVM is now included in `home_packages`
- **Rationale:** NVM is currently installed via Homebrew on the existing environment. v2 aims for complete environment reproduction, so NVM is included. (Overrides v1 D18 which excluded NVM.)
