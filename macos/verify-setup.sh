#!/bin/bash
# verify-setup.sh — Run after new-mac.sh to verify full environment

PASS=0
FAIL=0

check() {
  local desc=$1; shift
  if "$@" &>/dev/null; then
    echo "  ✅ $desc"; PASS=$((PASS + 1))
  else
    echo "  ❌ $desc"; FAIL=$((FAIL + 1))
  fi
}

# Helper for checks that need pipes (pipes can't be passed as arguments to check)
check_grep() {
  local desc=$1
  local haystack=$2
  local needle=$3
  if echo "$haystack" | grep -qi "$needle"; then
    echo "  ✅ $desc"; PASS=$((PASS + 1))
  else
    echo "  ❌ $desc"; FAIL=$((FAIL + 1))
  fi
}

echo "=== Dock Apps ==="
for app in "iTerm" "Notes" "WhatsApp" "Transmission" "VLC" "Calendar" \
           "System Settings" "Stremio" "TV" "Brave Browser" "iPhone Mirroring" \
           "Audacity" "Visual Studio Code" "Simulator"; do
  check "$app in Dock" dockutil --find "$app"
done

echo ""
echo "=== Dock Preferences ==="
check "Show recents disabled" test "$(defaults read com.apple.dock show-recents)" = "0"
check "Tile size 44" test "$(defaults read com.apple.dock tilesize)" = "44"
check "Magnification on" test "$(defaults read com.apple.dock magnification)" = "1"
check "Large size 128" test "$(defaults read com.apple.dock largesize)" = "128"
check "Auto-hide on" test "$(defaults read com.apple.dock autohide)" = "1"

echo ""
echo "=== System Preferences ==="
check "Hot corner BR: Quick Note" test "$(defaults read com.apple.dock wvous-br-corner)" = "14"
check "Accent color: Pink" test "$(defaults read NSGlobalDomain AppleAccentColor)" = "6"
check "Mission Control: group by app" test "$(defaults read com.apple.dock expose-group-apps)" = "1"
check "Mission Control: no auto-rearrange" test "$(defaults read com.apple.dock mru-spaces)" = "0"
check "Finder: column view" test "$(defaults read com.apple.finder FXPreferredViewStyle)" = "clmv"

echo ""
echo "=== Power Management ==="
check "AC display sleep: never" test "$(pmset -g custom | awk '/AC Power/{found=1} found && /displaysleep/{print $2; exit}')" = "0"
check "AC system sleep: never" test "$(pmset -g custom | awk '/AC Power/{found=1} found && /^ sleep/{print $2; exit}')" = "0"
check "Battery display sleep: 10" test "$(pmset -g custom | awk '/Battery Power/{found=1} found && /displaysleep/{print $2; exit}')" = "10"
check "Battery system sleep: 1" test "$(pmset -g custom | awk '/Battery Power/{found=1} found && /^ sleep/{print $2; exit}')" = "1"

echo ""
echo "=== Default Browser ==="
BROWSER_HANDLERS=$(plutil -extract LSHandlers json -o - \
  ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist 2>/dev/null || echo "")
check_grep "Brave is default browser" "$BROWSER_HANDLERS" "com.brave.Browser"

echo ""
echo "=== Login Items ==="
LOGIN_ITEMS=$(osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null || echo "")
for app in "Caffeine" "noTunes" "Magnet" "Bluesnooze" "Google Drive" "Raycast"; do
  check_grep "$app is login item" "$LOGIN_ITEMS" "$app"
done

echo ""
echo "=== Homebrew Packages (sample) ==="
check "bat installed" brew list bat
check "fzf installed" brew list fzf
check "tmux installed" brew list tmux
check "mas installed" brew list mas
check "dockutil installed" brew list dockutil

echo ""
echo "=== Shell Config ==="
check "aliases.zsh exists" test -f "$HOME/.aliases.zsh"
check "aliases.zsh sourced in zshrc" grep -q 'aliases.zsh' "$HOME/.zshrc"
check "docker alias defined" grep -q "alias docker='podman'" "$HOME/.aliases.zsh"
check "docker-compose alias defined" grep -q "alias docker-compose='podman-compose'" "$HOME/.aliases.zsh"

echo ""
echo "=== Compose File ==="
check "docker-compose.yml exists in repo" test -f "$(dirname "$0")/docker-compose.yml"

echo ""
echo "Results: $PASS passed, $FAIL failed"
