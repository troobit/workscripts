#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Resolve this script's directory so repo-managed files (Brewfile,
# sync-config.sh) are found whether run from a clone or re-run in place.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

########### PACKAGE CONFIGURATION ################
# Packages are defined in the repo-managed manifest macos/Brewfile (Req 2.1),
# installed below via `brew bundle`. Edit that data file to change what gets
# installed — no script code changes needed.

# --local: home-directory-only, no-sudo mode for testing on the current Mac
# (Req 3.4). It runs the Brewfile install and sync-config.sh, and SKIPS the
# interactive SSH/gh phase, sudo credentials + keep-alive, and every
# sudo/system side-effect section (system preferences, Dock, power management,
# headless, default browser, login items).
LOCAL=0
for arg in "$@"; do
  case "$arg" in
    --local) LOCAL=1 ;;
  esac
done

echo "🚀 Starting new Mac setup..."

########### INTERACTIVE PHASE ################
# User must be present for this section

# Install Xcode command line tools if they aren't already installed
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
else
  echo "Xcode Command Line Tools already installed."
fi

# Install Homebrew if it isn't already installed
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed."
fi

# IMPORTANT: Add Homebrew to the current shell session's PATH
# This is crucial for Apple Silicon Macs
if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install gh early — needed for SSH/GitHub auth in interactive phase
brew install gh 2>/dev/null || true

if [ "$LOCAL" != "1" ]; then

# Collect user input upfront
echo "📝 Collecting user information..."
while true; do
  read -rp "Enter your GitHub email: " GITHUB_EMAIL
  [ -n "$GITHUB_EMAIL" ] && break
  echo "⚠️  Email cannot be empty. Please try again."
done

while true; do
  read -rp "Enter your full name for Git: " GIT_NAME
  [ -n "$GIT_NAME" ] && break
  echo "⚠️  Name cannot be empty. Please try again."
done

########### SSH KEY SETUP ################

if [ ! -f "$HOME/.ssh/github" ]; then
  echo "🔑 Generating SSH key..."
  mkdir -p "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$HOME/.ssh/github" -N ""

  echo "Starting SSH agent..."
  eval "$(ssh-agent -s)"

  echo "Adding SSH key to agent..."
  ssh-add "$HOME/.ssh/github"

  echo "Authenticating with GitHub..."
  gh auth login --git-protocol ssh --web

  echo "Checking for existing SSH key on GitHub..."
  KEY_FINGERPRINT=$(ssh-keygen -lf "$HOME/.ssh/github.pub" | awk '{print $2}')
  if gh ssh-key list | grep -q "$KEY_FINGERPRINT"; then
    echo "⚠️  SSH key already uploaded to GitHub (fingerprint: $KEY_FINGERPRINT)"
  else
    echo "Uploading SSH key to GitHub..."
    gh ssh-key add "$HOME/.ssh/github.pub" --title "MacBook-$(date +%Y%m%d)" \
      || echo "⚠️  Could not upload SSH key — add ~/.ssh/github.pub manually at https://github.com/settings/keys"
  fi

  echo "Testing SSH connection..."
  ssh -T git@github.com -i "$HOME/.ssh/github" 2>&1 || echo "SSH test completed (expected authentication message)"

  echo "✅ SSH key setup complete"
else
  echo "✅ SSH key already exists at ~/.ssh/github"
fi
echo ""

########### SUDO CREDENTIALS ################

echo "🔐 Requesting administrator access for system configuration..."
sudo -v

# Keep sudo alive in the background. `sudo -n` never prompts: if the cached
# credential is ever revoked the loop's sudo fails silently (stderr to
# /dev/null) and simply retries — the loop itself never exits, and because
# it is a background job an inner failure cannot trip the script's set -e.
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!

# Kill keep-alive on any exit (success, set -e abort, or signal). `|| true`
# so a failing kill inside the trap can't overwrite the script's exit code.
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

echo ""
echo "🚀 Unattended phase starting — you can walk away now"
echo ""

else
  echo "⏭️  --local: skipping interactive SSH/gh phase and sudo credentials"
fi

########### UNATTENDED PHASE ################
# No further user interaction required

# Initialize logging — capture all unattended operations.
# Interplay notes (set -e + tee + keep-alive):
# - This runs AFTER the EXIT trap is installed, so an abort mid-phase still
#   kills the sudo keep-alive loop.
# - tee runs as a process substitution; on exit it may flush the last lines
#   slightly after the prompt returns. That is cosmetic only.
# - set -e is still active: every command below that may legitimately fail
#   (network, missing app, App Store not signed in) is wrapped in `if`/`||`
#   so one failure cannot silently skip the rest of the unattended phase.
SETUP_LOG="$HOME/SETUP.log"
exec > >(tee -a "$SETUP_LOG") 2>&1
echo "=== Setup started at $(date) ==="

echo "Updating Homebrew..."
brew update || echo "⚠️  brew update failed — continuing with existing package index"

brew install --cask font-droid-sans-mono-nerd-font || echo "Nerd font already installed or failed."

# Install Oh-My-Zsh if it isn't installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh-My-Zsh..."
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh already installed."
fi

# Clone Zsh plugins only if they don't exist
ZSH_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
if [ ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]; then
  echo "Cloning zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS_DIR/zsh-autosuggestions" \
    || echo "⚠️  Could not clone zsh-autosuggestions — re-run to retry"
else
  echo "zsh-autosuggestions plugin already exists."
fi


########### BREW PACKAGE INSTALL (Brewfile manifest) ################

# Kept for the summary block below. `brew bundle` reports its own failures
# inline via `brew bundle check`, so this stays empty.
FAILED_PACKAGES=()

BREWFILE="$SCRIPT_DIR/Brewfile"
if [ -f "$BREWFILE" ]; then
  echo "📦 Installing packages from Brewfile ($BREWFILE)..."
  # `brew bundle` installs formulae, casks, and mas apps, skipping already
  # installed entries, continuing past a failed entry, and exiting non-zero if
  # any failed — which `|| true` absorbs (Req 2.2). No --no-lock: that flag was
  # removed from modern Homebrew. mas entries are skipped with a non-fatal
  # error when the App Store is not signed in; the run continues (Req 2.4).
  brew bundle --file "$BREWFILE" || true
  # Failure summary: `check --verbose` names any entry still unsatisfied.
  echo "Checking Brewfile status (unsatisfied entries, if any, listed below):"
  brew bundle check --file "$BREWFILE" --verbose || true
else
  echo "⚠️  Brewfile not found at $BREWFILE — skipping package install (re-run from the workscripts clone)"
fi

########### SHELL CONFIGURATION (linked via sync-config.sh) ################

# Link repo-managed shell config into $HOME, migrate any legacy curl-appended
# ~/.zshrc block, and splice the managed source block (Reqs 1, 3, 4). This
# replaces the old curl-download-and-append of vimrc/zshrc/aliases so a `git
# pull` in the repo updates every machine. No sudo, no side effects outside
# $HOME. Idempotent: re-running makes no backup and no change once converged.
SYNC_CONFIG="$SCRIPT_DIR/sync-config.sh"
if [ -f "$SYNC_CONFIG" ]; then
  echo "🔧 Linking shell configuration via sync-config.sh..."
  bash "$SYNC_CONFIG" || echo "⚠️  sync-config.sh reported an error — continuing"
else
  echo "⚠️  sync-config.sh not found at $SYNC_CONFIG — skipping shell config linking (re-run from the workscripts clone)"
fi

if [ "$LOCAL" != "1" ]; then

########### SYSTEM PREFERENCES ################

echo "⚙️  Configuring system preferences..."

# Hot corners — bottom-right: Quick Note (14)
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0

# Appearance — accent color: Pink (6), highlight color: Green
defaults write NSGlobalDomain AppleAccentColor -int 6
defaults write NSGlobalDomain AppleHighlightColor -string "0.752941 0.964706 0.678431 Green"

# Mission Control — group by app, don't auto-rearrange spaces
defaults write com.apple.dock expose-group-apps -bool true
defaults write com.apple.dock mru-spaces -bool false

# Finder — column view as default
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
killall Finder || true

echo "✅ System preferences configured"

########### DOCK CONFIGURATION ################

echo "🖥️  Configuring Dock..."

# Define desired Dock apps — parallel indexed arrays (bash 3.2 compatible)
# "SPACER" entries in DOCK_NAMES trigger spacer tile insertion
DOCK_NAMES=(
  "iTerm" "Notes" "SPACER"
  "WhatsApp" "SPACER"
  "Transmission" "VLC" "Calendar" "System Settings"
  "Stremio" "TV" "Brave Browser" "iPhone Mirroring"
  "Audacity" "Visual Studio Code" "Simulator"
)
DOCK_PATHS=(
  "/Applications/iTerm.app"
  "/System/Applications/Notes.app"
  ""
  "/Applications/WhatsApp.app"
  ""
  "/Applications/Transmission.app"
  "/Applications/VLC.app"
  "/System/Applications/Calendar.app"
  "/System/Applications/System Settings.app"
  "/Applications/Stremio.app"
  "/System/Applications/TV.app"
  "/Applications/Brave Browser.app"
  "/System/Applications/iPhone Mirroring.app"
  "/Applications/Audacity.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"
)

if command -v dockutil &>/dev/null; then
  # Snapshot current Dock state for recovery reference
  echo "Current Dock state:"
  dockutil --list || true

  # Remove all existing Dock items (Finder preserved by macOS)
  dockutil --remove all --no-restart || echo "⚠️  dockutil remove failed"

  # Add each app/spacer in order
  for i in "${!DOCK_NAMES[@]}"; do
    app_name="${DOCK_NAMES[$i]}"
    app_path="${DOCK_PATHS[$i]}"

    if [ "$app_name" = "SPACER" ]; then
      dockutil --add '' --type spacer --section apps --no-restart \
        || echo "⚠️  Could not add spacer"
    elif [ -d "$app_path" ]; then
      dockutil --add "$app_path" --no-restart \
        || echo "⚠️  Could not add $app_name to Dock"
    else
      echo "⚠️  $app_name not found at $app_path — skipping"
    fi
  done

  # Add Downloads folder to persistent-others section
  dockutil --add "$HOME/Downloads" --section others --no-restart \
    || echo "⚠️  Could not add Downloads folder to Dock"

  # Dock preferences
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock tilesize -int 44
  defaults write com.apple.dock magnification -bool true
  defaults write com.apple.dock largesize -int 128
  defaults write com.apple.dock autohide -bool true

  # Single Dock restart to apply all changes
  killall Dock || true
  echo "✅ Dock configured"
else
  echo "⚠️  dockutil not found — skipping Dock configuration"
fi

########### POWER MANAGEMENT ################

echo "⚡ Configuring power management..."

# AC Power — never sleep
sudo pmset -c displaysleep 0 || echo "⚠️  Could not set AC display sleep"
sudo pmset -c sleep 0 || echo "⚠️  Could not set AC system sleep"

# Battery — conservative sleep
sudo pmset -b displaysleep 10 || echo "⚠️  Could not set battery display sleep"
sudo pmset -b sleep 1 || echo "⚠️  Could not set battery system sleep"

echo "✅ Power management configured"

########### HEADLESS OPERATION ################
# This machine is intended to run always-on in clamshell mode (lid closed,
# on AC power, no external display) and be reached over SSH/Tailscale.

echo "🖥️  Configuring headless operation..."

# Remote Login (SSH). systemsetup is idempotent — setting it on when it is
# already on succeeds without side effects, so re-runs are safe.
if sudo systemsetup -getremotelogin 2>/dev/null | grep -qi "on$"; then
  echo "✅ Remote Login (SSH) already enabled"
else
  sudo systemsetup -setremotelogin on \
    || echo "⚠️  Could not enable Remote Login — enable in System Settings → General → Sharing"
fi

# Prevent sleep entirely, including with the lid closed. Plain `pmset sleep 0`
# is not enough for clamshell: without an external display macOS still sleeps
# on lid close. `disablesleep 1` overrides that (same mechanism used for
# clamshell servers). Trade-off: it also disables sleep on battery, so a
# power cut runs the battery down — acceptable for an always-plugged-in
# server. Revert with: sudo pmset -a disablesleep 0
sudo pmset -a disablesleep 1 || echo "⚠️  Could not set disablesleep"

# Auto-restart after power failure, so the machine comes back unattended.
sudo systemsetup -setrestartpowerfailure on 2>/dev/null \
  || sudo pmset -a autorestart 1 \
  || echo "⚠️  Could not enable auto-restart after power failure"

echo "✅ Headless operation configured"

########### DEFAULT BROWSER ################

echo "🌐 Setting default browser..."

if [ -d "/Applications/Brave Browser.app" ]; then
  if ! command -v swift >/dev/null 2>&1; then
    echo "⚠️  swift not found; skipping default browser setup"
  else
    # Start AppleScript to auto-dismiss the confirmation dialog
    osascript <<'APPLESCRIPT' &
      tell application "System Events"
        repeat 30 times
          try
            tell process "CoreServicesUIAgent"
              click button 2 of window 1
            end tell
            exit repeat
          end try
          delay 0.5
        end repeat
      end tell
APPLESCRIPT
    DIALOG_PID=$!

    # Set default browser via NSWorkspace API (macOS 12+).
    # NOTE: the heredoc body must start on the line directly after the `if`
    # line and `then` must come after the closing SWIFT delimiter — putting
    # `then`-branch lines before the heredoc body feeds them to swift as
    # source code and breaks the shell parse (this was a past defect).
    if swift <<'SWIFT'
import AppKit
let ws = NSWorkspace.shared
guard let url = ws.urlForApplication(withBundleIdentifier: "com.brave.Browser") else {
  fputs("Brave Browser not found\n", stderr)
  exit(1)
}
let sem = DispatchSemaphore(value: 0)
var exitCode: Int32 = 0
ws.setDefaultApplication(at: url, toOpenURLsWithScheme: "http") { error in
  if let error = error { fputs("http: \(error)\n", stderr); exitCode = 1 }
  ws.setDefaultApplication(at: url, toOpenURLsWithScheme: "https") { error in
    if let error = error { fputs("https: \(error)\n", stderr); exitCode = 1 }
    sem.signal()
  }
}
sem.wait()
exit(exitCode)
SWIFT
    then
      echo "✅ Default browser set to Brave"
    else
      # Failure path: swift compile/runtime errors land in the log via the
      # tee redirection; the `if` guard keeps set -e from aborting the run.
      echo "⚠️  Could not set default browser with swift"
    fi

    # Clean up dialog handler. Both must be || true under set -e: kill fails
    # if osascript already finished, and wait returns 143 for a killed child
    # — either would otherwise abort the whole script here.
    kill "$DIALOG_PID" 2>/dev/null || true
    wait "$DIALOG_PID" 2>/dev/null || true
  fi
else
  echo "⚠️  Brave Browser not installed — skipping default browser"
fi

########### LOGIN ITEMS ################

echo "🔑 Configuring login items..."

LOGIN_APPS=(
  "/Applications/Caffeine.app"
  "/Applications/noTunes.app"
  "/Applications/Magnet.app"
  "/Applications/Bluesnooze.app"
  "/Applications/Google Drive.app"
  "/Applications/Raycast.app"
)

# Get current login items
CURRENT_LOGIN_ITEMS=$(osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null || echo "")

for app_path in "${LOGIN_APPS[@]}"; do
  app_name=$(basename "$app_path" .app)

  if [ ! -d "$app_path" ]; then
    echo "⚠️  $app_name not installed — skipping login item"
    continue
  fi

  if echo "$CURRENT_LOGIN_ITEMS" | grep -qi "$app_name"; then
    echo "✅ $app_name already a login item"
  else
    osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:false}" \
      || echo "⚠️  Could not add $app_name as login item"
    echo "✅ Added $app_name as login item"
  fi
done

echo "✅ Login items configured"

else
  echo "⏭️  --local: skipping system preferences, Dock, power management, headless, default browser and login items"
fi

# Verify required dependencies are available
echo "🔍 Verifying required dependencies..."
for cmd in gh go git; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ Required dependency '$cmd' not found. Ensure it was installed by Homebrew above."
    exit 1
  fi
done
echo "✅ All required dependencies found."

########### GIT CONFIGURATION SETUP ################

# GIT_NAME/GITHUB_EMAIL are only collected in the interactive phase, which
# --local skips — writing the heredoc without them would create a ~/.gitconfig
# with empty name/email.
if [ ! -f "$HOME/.gitconfig" ] && { [ -z "${GIT_NAME:-}" ] || [ -z "${GITHUB_EMAIL:-}" ]; }; then
  echo "⏭️  --local: skipping ~/.gitconfig creation (name/email not collected)"
elif [ ! -f "$HOME/.gitconfig" ]; then
  echo "⚙️  Setting up Git configuration..."
  cat > "$HOME/.gitconfig" <<EOF
[user]
	name = $GIT_NAME
	email = $GITHUB_EMAIL

[core]
	sshCommand = ssh -i ~/.ssh/github

; include for all repositories inside \$HOME/Repos/SPECIFIC_FOLDER/
[includeIf "gitdir:~/Repos/SPECIFIC_FOLDER/"]
	path = ~/.gc/specific_config_file

; include for all repositories inside \$HOME/repos/another_specific_folder/
[includeIf "gitdir:~/repos/another_specific_folder/"]
	path = ~/.gc/another_conf_file

[push]
	autoSetupRemote = true

[pull]
	rebase = true

[init]
	defaultBranch = main

[pager]
	branch = false
	log = false

[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
EOF
  echo "✅ Git configuration created"
else
  echo "✅ Git configuration already exists at ~/.gitconfig"
fi
echo ""

########### REPOSITORY SETUP ################

# Create repos directory
if [ ! -d "$HOME/repos" ]; then
  echo "📁 Creating ~/repos/ directory..."
  mkdir -p "$HOME/repos"
  echo "✅ ~/repos/ directory created"
else
  echo "✅ ~/repos/ directory already exists"
fi
echo ""

# Clone repositories
echo "📦 Cloning repositories..."

REPOS_CLONED=0
REPOS_TOTAL=4

clone_repo() {
  local org=$1
  local repo=$2
  local target="$HOME/repos/$repo"

  if [ -d "$target/.git" ]; then
    echo "✅ $org/$repo already cloned"
    REPOS_CLONED=$((REPOS_CLONED + 1))
  else
    echo "Cloning $org/$repo..."
    if git clone "git@github.com:$org/$repo.git" "$target" 2>&1; then
      echo "✅ $org/$repo cloned successfully"
      REPOS_CLONED=$((REPOS_CLONED + 1))
    else
      echo "❌ Failed to clone $org/$repo" >&2
    fi
  fi
}

clone_repo "troobit" "workscripts"
clone_repo "ArjenSchwarz" "rune"
clone_repo "ArjenSchwarz" "orbit"
clone_repo "ArjenSchwarz" "agentic-coding"

echo "✅ Repository cloning complete ($REPOS_CLONED/$REPOS_TOTAL repositories available)"
echo ""

########### CLAUDE CODE SKILLS SYMLINK ################

SYMLINK_SETUP=0

if [ -d "$HOME/repos/agentic-coding/claude/skills" ]; then
  echo "🔗 Setting up Claude Code skills symlink..."

  # Task 16: Create ~/.claude directory if it doesn't exist
  mkdir -p "$HOME/.claude"

  TARGET="$HOME/repos/agentic-coding/claude/skills"
  LINK="$HOME/.claude/skills"

  # Task 17: Check symlink existence and validate
  if [ -L "$LINK" ]; then
    CURRENT_TARGET=$(readlink "$LINK")
    if [ "$CURRENT_TARGET" = "$TARGET" ]; then
      echo "✅ Claude Code skills symlink already points to correct location"
      SYMLINK_SETUP=1
    else
      echo "⚠️  Warning: ~/.claude/skills points to $CURRENT_TARGET (expected $TARGET)" >&2
    fi
  elif [ -e "$LINK" ]; then
    # Task 18: Something exists but is not a symlink - warn, don't overwrite
    echo "⚠️  Warning: ~/.claude/skills exists but is not a symlink" >&2
  else
    # Task 18: Create symlink
    if ln -s "$TARGET" "$LINK"; then
      echo "✅ Claude Code skills symlink created"
      SYMLINK_SETUP=1
    else
      echo "❌ Failed to create Claude Code skills symlink" >&2
    fi
  fi
else
  echo "⚠️  Skipping Claude Code skills symlink - agentic-coding repository not available" >&2
fi
echo ""

########### GO TOOL INSTALLATION ################

echo "🔧 Installing Go tools..."

TOOLS_INSTALLED=0
TOOLS_TOTAL=2

install_tool() {
  local repo_name=$1
  local repo_path="$HOME/repos/$repo_name"

  if [ ! -d "$repo_path/.git" ]; then
    echo "⚠️  Skipping $repo_name - repository not available" >&2
    return
  fi

  echo "Installing $repo_name..."
  if (cd "$repo_path" && [ -f "Makefile" ] && make install 2>&1); then
    echo "✅ $repo_name installed via make install"
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
  elif (cd "$repo_path" && go install ./... 2>&1); then
    echo "✅ $repo_name installed via go install"
    TOOLS_INSTALLED=$((TOOLS_INSTALLED + 1))
  else
    echo "❌ Failed to install $repo_name" >&2
  fi
}

install_tool "rune"
install_tool "orbit"

echo "✅ Tool installation complete ($TOOLS_INSTALLED/$TOOLS_TOTAL tools installed)"

# Verify PATH includes ~/go/bin
if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
  echo "⚠️  Warning: ~/go/bin not in PATH. Add to your shell config:" >&2
  echo "    export PATH=\"\$HOME/go/bin:\$PATH\"" >&2
fi

# Verify tools are accessible
for tool in rune orbit; do
  if command -v "$tool" &>/dev/null; then
    echo "✅ $tool available: $(command -v "$tool")"
  else
    echo "⚠️  $tool not found in PATH after installation"
  fi
done
echo ""

########### APP-LEVEL SETTINGS (STRETCH) ################

# iTerm2 preferences import
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ITERM_PLIST="$SCRIPT_DIR/iterm2-prefs.plist"
if [ -f "$ITERM_PLIST" ] && [ -d "/Applications/iTerm.app" ]; then
  echo "Importing iTerm2 preferences..."
  defaults import com.googlecode.iterm2 "$ITERM_PLIST" \
    || echo "Could not import iTerm2 preferences"
  echo "iTerm2 preferences imported"
else
  if [ ! -d "/Applications/iTerm.app" ]; then
    echo "iTerm2 not installed — skipping preferences import"
  elif [ ! -f "$ITERM_PLIST" ]; then
    echo "iterm2-prefs.plist not found — skipping preferences import"
  fi
fi

########### SUMMARY ################

# Kill sudo keep-alive — no longer needed
kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true

echo ""
echo "=== Setup Summary ==="
echo "Repositories: $REPOS_CLONED/$REPOS_TOTAL available"
echo "Go tools:     $TOOLS_INSTALLED/$TOOLS_TOTAL installed"
if [ "${#FAILED_PACKAGES[@]}" -gt 0 ]; then
  echo "Failed pkgs:  ${FAILED_PACKAGES[*]}"
fi
echo ""

if [ "$REPOS_CLONED" -gt 0 ] || [ "$TOOLS_INSTALLED" -gt 0 ] || [ "$SYMLINK_SETUP" -eq 1 ]; then
  if [ "$SYMLINK_SETUP" -eq 1 ]; then
    echo "✅ Setup complete! Successfully set up $REPOS_CLONED/$REPOS_TOTAL repositories, symlink, and $TOOLS_INSTALLED/$TOOLS_TOTAL tools."
  else
    echo "✅ Setup complete! Successfully set up $REPOS_CLONED/$REPOS_TOTAL repositories and $TOOLS_INSTALLED/$TOOLS_TOTAL tools."
  fi
else
  echo "⚠️  Setup completed with issues. Check ~/SETUP.log for details."
fi

if [ "${#FAILED_PACKAGES[@]}" -gt 0 ]; then
  echo ""
  echo "⚠️  The following packages failed to install:"
  for pkg in "${FAILED_PACKAGES[@]}"; do
    echo "    - $pkg  (run: brew info $pkg)"
  done
  echo "Fix any invalid names in the PACKAGE CONFIGURATION block and re-run the script."
fi

# Consolidated manual sign-ins — every remaining interactive login in one
# place. GitHub was already handled in the interactive phase (gh auth login).
# This list is mirrored in docs/new-mac-localhost.md.
echo ""
echo "=== Manual sign-ins still required ==="
echo "  [ ] Tailscale   — open Tailscale.app, sign in to your tailnet (browser)"
echo "  [ ] Claude Code — run: claude   (first run opens browser login)"
echo "  [ ] App Store   — sign in with your Apple ID so mas can install/update apps"
echo "                    then re-run: mas install 441258766   # Magnet"
echo "  [x] GitHub      — done in the interactive phase (verify: gh auth status)"
echo ""
echo "Restart your terminal to apply all changes."
