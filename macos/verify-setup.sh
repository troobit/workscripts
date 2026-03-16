#!/bin/bash
# verify-setup.sh — Run after new-mac.sh to verify mac-env-setup changes

PASS=0
FAIL=0

check() {
  local desc=$1; shift
  if "$@" &>/dev/null; then
    echo "✅ $desc"; PASS=$((PASS + 1))
  else
    echo "❌ $desc"; FAIL=$((FAIL + 1))
  fi
}

echo "=== Dock Configuration ==="
check "Brave Browser in Dock" dockutil --find "Brave Browser"
check "WhatsApp in Dock" dockutil --find "WhatsApp"
check "iTerm in Dock" dockutil --find "iTerm2"
check "Calendar in Dock" dockutil --find "Calendar"
check "Recent apps disabled" test "$(defaults read com.apple.dock show-recents)" = "0"

echo ""
echo "=== Homebrew Packages ==="
check "brave-browser installed" brew list --cask brave-browser
check "whatsapp installed" brew list --cask whatsapp
check "dockutil installed" brew list dockutil
check "podman installed" brew list podman
check "podman-compose installed" brew list podman-compose

echo ""
echo "=== Shell Configuration ==="
check "aliases.zsh exists" test -f "$HOME/.aliases.zsh"
check "aliases.zsh sourced in zshrc" grep -q 'aliases.zsh' "$HOME/.zshrc"
check "docker alias defined" grep -q "alias docker='podman'" "$HOME/.aliases.zsh"
check "docker-compose alias defined" grep -q "alias docker-compose='podman-compose'" "$HOME/.aliases.zsh"

echo ""
echo "=== Compose File ==="
check "docker-compose.yml exists in repo" test -f "$(dirname "$0")/docker-compose.yml"

echo ""
echo "Results: $PASS passed, $FAIL failed"
