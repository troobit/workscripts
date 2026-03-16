#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🚀 Starting new Mac setup..."

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

echo "Updating Homebrew..."
brew update

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
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
else
  echo "zsh-autosuggestions plugin already exists."
fi


########### BREW PACKAGE LIST ################
default_packages=("rename" "git" "jq" "notunes" "bluesnooze" "firefox" "gimp" "google-chrome" "iterm2" "logitech-options" "nordvpn" "raycast" "session-manager-plugin" "visual-studio-code" "wireshark" "gh" "go" "brave-browser" "whatsapp" "dockutil")
work_packages=("slack" "microsoft-teams" "terraform")
home_packages=("transmission" "vlc" "awscli" "azure-cli" "podman" "podman-compose")

# Combine all packages into one list
all_packages=("${default_packages[@]}" "${home_packages[@]}")


echo "Installing brew packages..."
brew install "${all_packages[@]}" || echo "Could not install some packages. They might already be installed or are not available."

# Download config files, but check if they exist first to avoid duplication
if [ ! -f "$HOME/.vimrc" ]; then
    echo "Downloading .vimrc..."
    curl -o "$HOME/.vimrc" https://raw.githubusercontent.com/troobit/workscripts/main/macos/vimrc
fi

if ! grep -q "troobit/workscripts" "$HOME/.zshrc"; then
    echo "Appending custom .zshrc settings..."
    # Add a comment to prevent re-adding in the future
    echo "\n# Added from troobit/workscripts setup script" >> "$HOME/.zshrc"
    curl https://raw.githubusercontent.com/troobit/workscripts/main/macos/zshrc >> "$HOME/.zshrc"
fi

########### DEVELOPER SETUP ################

# Initialize logging
SETUP_LOG="$HOME/SETUP.log"
exec > >(tee -a "$SETUP_LOG") 2>&1
echo "=== Developer setup started at $(date) ==="

########### SHELL CONFIGURATION ################

echo "🔧 Deploying shell configuration..."

# Download aliases.zsh (overwrite — repo-managed)
curl -fsSL -o "$HOME/.aliases.zsh" \
  https://raw.githubusercontent.com/troobit/workscripts/main/macos/aliases.zsh \
  || echo "⚠️  Could not download aliases.zsh"

# Source from .zshrc if not already present
if ! grep -q "source.*\.aliases\.zsh" "$HOME/.zshrc" 2>/dev/null; then
  echo '[ -f "$HOME/.aliases.zsh" ] && source "$HOME/.aliases.zsh"' >> "$HOME/.zshrc"
  echo "✅ Added aliases.zsh sourcing to .zshrc"
else
  echo "✅ aliases.zsh already sourced in .zshrc"
fi

########### DOCK CONFIGURATION ################

echo "🖥️  Configuring Dock..."

# Define desired Dock apps — two parallel indexed arrays (bash 3.2 compatible)
DOCK_NAMES=("Brave Browser" "WhatsApp" "iTerm" "Calendar")
DOCK_PATHS=(
  "/Applications/Brave Browser.app"
  "/Applications/WhatsApp.app"
  "/Applications/iTerm.app"
  "/System/Applications/Calendar.app"
)

if command -v dockutil &>/dev/null; then
  # Snapshot current Dock state for recovery reference
  echo "Current Dock state:"
  dockutil --list || true

  # Remove all existing Dock items (Finder preserved by macOS)
  dockutil --remove all --no-restart || echo "⚠️  dockutil remove failed"

  # Add each app in order
  for i in "${!DOCK_NAMES[@]}"; do
    app_name="${DOCK_NAMES[$i]}"
    app_path="${DOCK_PATHS[$i]}"
    if [ -d "$app_path" ]; then
      dockutil --add "$app_path" --no-restart || echo "⚠️  Could not add $app_name to Dock"
    else
      echo "⚠️  $app_name not found at $app_path — skipping Dock add"
    fi
  done

  # Disable recent apps in Dock
  defaults write com.apple.dock show-recents -bool false

  # Restart Dock to apply all changes
  killall Dock || true
  echo "✅ Dock configured"
else
  echo "⚠️  dockutil not found — skipping Dock configuration"
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
    gh ssh-key add "$HOME/.ssh/github.pub" --title "MacBook-$(date +%Y%m%d)"
  fi

  echo "Testing SSH connection..."
  ssh -T git@github.com -i "$HOME/.ssh/github" 2>&1 || echo "SSH test completed (expected authentication message)"

  echo "✅ SSH key setup complete"
else
  echo "✅ SSH key already exists at ~/.ssh/github"
fi
echo ""

########### GIT CONFIGURATION SETUP ################

if [ ! -f "$HOME/.gitconfig" ]; then
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

########### SUMMARY ################

echo ""
echo "=== Setup Summary ==="
echo "Repositories: $REPOS_CLONED/$REPOS_TOTAL available"
echo "Go tools:     $TOOLS_INSTALLED/$TOOLS_TOTAL installed"
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

echo "Restart your terminal to apply all changes."
