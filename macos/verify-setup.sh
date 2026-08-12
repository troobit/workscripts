#!/bin/bash
# verify-setup.sh — Run after new-mac.sh to verify full environment

PASS=0
FAIL=0

# Repo macos/ dir (this script's dir), plus the managed marker strings that
# sync-config.sh splices into ~/.zshrc — kept in sync with sync-config.sh.
MACOS_DIR="$(cd "$(dirname "$0")" && pwd)"
MANAGED_BEGIN="# >>> workscripts skup (managed) >>>"
MANAGED_END="# <<< workscripts skup (managed) <<<"
MANAGED_POST_BEGIN="# >>> workscripts skup aliases (managed) >>>"
MANAGED_POST_END="# <<< workscripts skup aliases (managed) <<<"
ALIAS_SRC='[ -f "$HOME/.aliases.zsh" ] && source "$HOME/.aliases.zsh"'

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

# --- Predicates for the converged-state (skup) checks ------------------------
# LINK is a symlink whose target is exactly TARGET (a file inside the repo).
link_points_to() {
  local link="$1" target="$2"
  [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]
}

# FILE contains exactly WANT lines equal (whole-line) to LINE.
line_count_is() {
  local file="$1" line="$2" want="$3"
  [ "$(grep -Fxc -- "$line" "$file" 2>/dev/null)" = "$want" ]
}

# Fixed PAT is NOT present anywhere in FILE.
absent_fixed() {
  local file="$1" pat="$2"
  ! grep -Fq -- "$pat" "$file" 2>/dev/null
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
echo "=== Headless Operation ==="
# systemsetup needs root; sudo -n avoids hanging on a password prompt when
# run non-interactively (the check just fails instead).
check_grep "Remote Login (SSH) enabled" \
  "$(sudo -n systemsetup -getremotelogin 2>/dev/null || echo unavailable)" "On"
check "Tailscale app installed" test -d "/Applications/Tailscale.app"
check "Tailscale logged in" /Applications/Tailscale.app/Contents/MacOS/Tailscale status
check_grep "Sleep disabled (clamshell always-on)" \
  "$(pmset -g | grep SleepDisabled)" "1"
check_grep "Auto-restart after power failure" \
  "$(pmset -g | grep autorestart)" "1"

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

# --- Converged end state after sync-config.sh (specs/skup, Req 3.5, 4.1) -----
echo ""
echo "=== skup: Managed Links ==="
check "aliases.zsh links into repo" \
  link_points_to "$HOME/.aliases.zsh" "$MACOS_DIR/aliases.zsh"
check "vimrc links into repo" \
  link_points_to "$HOME/.vimrc" "$MACOS_DIR/vimrc"
check "zshrc.workscripts links into repo snippet" \
  link_points_to "$HOME/.zshrc.workscripts" "$MACOS_DIR/zshrc.snippet"
check "local/bin/skup links into repo" \
  link_points_to "$HOME/.local/bin/skup" "$MACOS_DIR/skup"
check "local/bin/skup is executable" test -x "$HOME/.local/bin/skup"

echo ""
echo "=== skup: Managed zshrc Block ==="
check "exactly one managed begin marker in zshrc" \
  line_count_is "$HOME/.zshrc" "$MANAGED_BEGIN" 1
check "exactly one managed end marker in zshrc" \
  line_count_is "$HOME/.zshrc" "$MANAGED_END" 1
check "zshrc sources the repo snippet" \
  grep -Fq '.zshrc.workscripts' "$HOME/.zshrc"
check "no legacy troobit marker remains in zshrc" \
  absent_fixed "$HOME/.zshrc" "# Added from troobit/workscripts setup script"
check "exactly one managed aliases begin marker in zshrc" \
  line_count_is "$HOME/.zshrc" "$MANAGED_POST_BEGIN" 1
check "exactly one managed aliases end marker in zshrc" \
  line_count_is "$HOME/.zshrc" "$MANAGED_POST_END" 1
# The aliases file being linked is not enough — it must also still be SOURCED,
# and after oh-my-zsh so it overrides omz lib aliases rather than losing to them.
check "exactly one aliases source line in zshrc" \
  line_count_is "$HOME/.zshrc" "$ALIAS_SRC" 1
aliases_sourced_after_omz() {
  local a o
  a="$(grep -Fxn -- "$ALIAS_SRC" "$HOME/.zshrc" 2>/dev/null | head -1 | cut -d: -f1)"
  o="$(grep -En '^[[:space:]]*source[[:space:]]+"?\$ZSH"?/oh-my-zsh\.sh' "$HOME/.zshrc" 2>/dev/null | head -1 | cut -d: -f1)"
  [ -n "$a" ] && [ -n "$o" ] && [ "$a" -gt "$o" ]
}
check "aliases sourced after oh-my-zsh (override order)" aliases_sourced_after_omz

echo ""
echo "=== skup: Captured Drift Aliases ==="
# Content assertions (not mere definedness): a corrupted alias still "resolves".
check "alias t resolves to tmux" \
  grep -Fxq "alias t='tmux'" "$HOME/.aliases.zsh"
check "alias tk resolves to fixed kill-session form" \
  grep -Fxq "alias tk='tmux kill-session -t'" "$HOME/.aliases.zsh"
check "corrupted tk alias definition absent" \
  absent_fixed "$HOME/.aliases.zsh" "alias tk='tmux kill~session"
check "alias cld defined" \
  grep -Fq "alias cld='claude --dangerously-skip-permissions'" "$HOME/.aliases.zsh"
check "lorb() defined" \
  grep -Fq 'lorb() {' "$HOME/.aliases.zsh"

echo ""
echo "=== skup: Machine-Specific Config Kept Local ==="
# PRISMPATH/cppr exist only on machines that already carried them (prism work,
# used intermittently). A fresh machine has nothing to keep, so an unconditional
# "still present" assert would fail there, breaking Req 3.7 convergence.
# Instead: fail only when a pre-migration backup proves the machine had the
# setting and ~/.zshrc has since lost it; otherwise skip.
check_kept_local() {
  local pat="$1"
  if grep -Fq -- "$pat" "$HOME/.zshrc" 2>/dev/null; then
    echo "  ✅ $pat still present in zshrc"; PASS=$((PASS + 1))
  elif grep -Fq -- "$pat" "$HOME"/.workscripts-backups/.zshrc.* 2>/dev/null; then
    echo "  ❌ $pat lost from zshrc (present in pre-migration backup)"; FAIL=$((FAIL + 1))
  else
    echo "  ⚠️  $pat not configured on this machine (skipped)"
  fi
}
check_kept_local "PRISMPATH"
check_kept_local "cppr"
check "PRISMPATH not captured into repo aliases" absent_fixed "$MACOS_DIR/aliases.zsh" 'PRISMPATH'
check "PRISMPATH not captured into repo snippet" absent_fixed "$MACOS_DIR/zshrc.snippet" 'PRISMPATH'
check "cppr not captured into repo aliases" absent_fixed "$MACOS_DIR/aliases.zsh" 'cppr'

echo ""
echo "=== skup: Config ==="
# Source skup (its main is guarded off when sourced) to reuse the real parser,
# then confirm skup.conf yields a default set. $0 is passed as a sentinel so the
# sourced skup sees BASH_SOURCE[0] != $0 and does not run skup_main.
# shellcheck disable=SC2016  # $1/$2 are expanded by the inner bash, not here
check "skup.conf parses with a default set" \
  bash -c 'set +u; source "$1"; skup_parse_conf "$2"; skup_conf_get default >/dev/null' \
  verify-skup "$MACOS_DIR/skup" "$MACOS_DIR/skup.conf"
# Report each configured repo: present under repos_root or reported missing
# (informational — a repo not yet cloned does not fail the converged-state check).
bash -c '
  set +u
  source "$1"
  skup_parse_conf "$2"
  root="$(skup_repos_root)"
  seen=" "
  for i in "${!CONF_KEYS[@]}"; do
    case "${CONF_KEYS[$i]}" in
      default|tag.*) ;;
      *) continue ;;
    esac
    for repo in ${CONF_VALS[$i]}; do
      case "$seen" in *" $repo "*) continue ;; esac
      seen="$seen$repo "
      if [ -d "$root/$repo" ]; then
        echo "  ✅ repo $repo present under $root"
      else
        echo "  ⚠️  repo $repo not found under $root (reported)"
      fi
    done
  done
' verify-skup "$MACOS_DIR/skup" "$MACOS_DIR/skup.conf"

echo ""
echo "Results: $PASS passed, $FAIL failed"
