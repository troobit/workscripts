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
default_packages=("rename" "git" "jq" "notunes" "bluesnooze" "firefox" "gimp" "google-chrome" "iterm2" "logitech-options" "nordvpn" "raycast" "session-manager-plugin" "visual-studio-code" "wireshark")
work_packages=("slack" "microsoft-teams" "awscli" "azure-cli" "terraform")
home_packages=("transmission" "vlc")

# Combine all packages into one list
all_packages=("${default_packages[@]}" "${work_packages[@]}")


echo "Installing brew packages..."
# Corrected loop syntax to iterate over the array
for package in "${all_packages[@]}"; do
  echo "Installing $package..."
  # Use 'brew install' which handles both casks and formulae automatically
  brew install "$package" || echo "Could not install $package. It might already be installed or is not available."
done

# Download config files, but check if they exist first to avoid duplication
if [ ! -f "$HOME/.vimrc" ]; then
    echo "Downloading .vimrc..."
    curl -o "$HOME/.vimrc" https://raw.githubusercontent.com/rtobrien/workscripts/main/macos/vimrc
fi

if ! grep -q "rtobrien/workscripts" "$HOME/.zshrc"; then
    echo "Appending custom .zshrc settings..."
    # Add a comment to prevent re-adding in the future
    echo "\n# Added from rtobrien/workscripts setup script" >> "$HOME/.zshrc"
    curl https://raw.githubusercontent.com/rtobrien/workscripts/main/macos/zshrc >> "$HOME/.zshrc"
fi

echo "✅ Setup complete! Restart your terminal to apply all changes."
