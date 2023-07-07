#!/bin/bash

# Install xcode dev tools
xcode-select --install


# Install brew
eval $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
brew tap homebrew/cask-fonts
brew install --cask font-droid-sans-mono-nerd-font


# Install Oh-My-Zsh
eval $(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

########### BREW PACKAGE LIST ################
########### BREW PACKAGE LIST ################

work=("slack" "microsoft-teams" "awscli" "azure-cli" "terraform" "firefox")
default=("google-chrome" "defaultbrowser" "rename" "tldr" "bitwarden" "bitwarden-cli" "git" "jq" "notunes" "bluesnooze" "authy")
home=("transmission" "nord-vpn" "vlc")


for package in $work+$default; do
  brew install ---cask $package || brew install $package || echo "$package install failed with brew"
done

######## ADD SPACES TO DOCK #########
# Use the below line to add spacers - add as many by repeating cmd
# defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}'; killall Dock


curl https://raw.githubusercontent.com/rtobrien/workscripts/main/macos/vimrc >> ~/.vimrc
curl https://raw.githubusercontent.com/rtobrien/workscripts/main/macos/zshrc >> ~/.zshrc
