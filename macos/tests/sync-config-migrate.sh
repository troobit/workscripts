#!/bin/bash
# Tests for migrate_legacy_zshrc() in macos/sync-config.sh (Reqs 3.3, 4.2).
#
# Self-contained: operates on temp ~/.zshrc fixtures in a sandbox, never the
# real home directory. Sources sync-config.sh to get the function under test.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC="$SCRIPT_DIR/../sync-config.sh"

FAILS=0
pass() { printf 'ok   - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1"; FAILS=$((FAILS + 1)); }

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home"
mkdir -p "$HOME"
BACKUP_DIR="$HOME/.workscripts-backups"

# shellcheck source=/dev/null
source "$SYNC"

# --- Fixture A: full legacy ~/.zshrc (mirrors the live drifted state) --------
# Single-quoted heredoc: $ZSH, $PATH, $(brew...), $1 stay literal, and the
# corrupted `tk` keeps its trailing space.
zA="$SANDBOX/zA"
cat > "$zA" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=random
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Added from troobit/workscripts setup script
setopt shwordsplit
ZSH_THEME=random
plugins=(brew vim-interaction)
source $ZSH/oh-my-zsh.sh
export LSCOLORS='ExGxDxDxCxDxDxFxFxexEx'
[ -f "$HOME/.aliases.zsh" ] && source "$HOME/.aliases.zsh"
# Prefer Homebrew Python over system Python
export PATH="$(brew --prefix python)/bin:$PATH"
export LESS="-F -X $LESS"
alias t='tmux'
export PRISMPATH='/Users/r/Library/Mobile Documents/com~apple~CloudDocs/Prism Markdown'
cppr() {
    cp "$1" $PRISMPATH
}
alias cld='claude --dangerously-skip-permissions'
alias tk='tmux kill~session ~t '
lorb() {
    nohup orbit run --tasks-file "$1" --variants 1 --parallel > /dev/null 2>&1 &
}
EOF

cp "$zA" "$SANDBOX/zA.orig"
migrate_legacy_zshrc "$zA" >/dev/null

# 1. anchor-range deleted (marker + end anchor gone, and the SECOND omz source)
if ! grep -Fq "# Added from troobit/workscripts setup script" "$zA" \
   && ! grep -Fq 'export PATH="$(brew --prefix python)/bin:$PATH"' "$zA"; then
  pass "legacy anchor range deleted (both anchors gone)"
else
  fail "legacy anchor range deleted (both anchors gone)"
fi
if [ "$(grep -c 'source \$ZSH/oh-my-zsh.sh' "$zA")" -eq 1 ]; then
  pass "duplicate oh-my-zsh source line inside legacy region removed (one remains)"
else
  fail "duplicate oh-my-zsh source line inside legacy region removed (one remains)"
fi

# 2. the four drift lines removed
if ! grep -Fxq "alias t='tmux'" "$zA" \
   && ! grep -Fxq "alias cld='claude --dangerously-skip-permissions'" "$zA" \
   && ! grep -Fxq "alias tk='tmux kill~session ~t '" "$zA" \
   && ! grep -Fq "lorb() {" "$zA"; then
  pass "four captured drift lines removed"
else
  fail "four captured drift lines removed"
fi

# 3. machine-specific config left untouched
if grep -Fq "export PRISMPATH='/Users/r/Library/Mobile Documents/com~apple~CloudDocs/Prism Markdown'" "$zA" \
   && grep -Fq "cp \"\$1\" \$PRISMPATH" "$zA" \
   && grep -Fq 'export LESS="-F -X $LESS"' "$zA"; then
  pass "PRISMPATH, cppr and machine paths left untouched"
else
  fail "PRISMPATH, cppr and machine paths left untouched"
fi

# 4. whole-file backup taken before edit, equal to the original
backupA="$(find "$BACKUP_DIR" -name 'zA.*' 2>/dev/null | head -1)"
if [ -n "$backupA" ] && diff -q "$SANDBOX/zA.orig" "$backupA" >/dev/null; then
  pass "whole-file backup taken before edit (matches original)"
else
  fail "whole-file backup taken before edit (matches original)"
fi

# --- Fixture B: missing end anchor -> skip range deletion, report ------------
rm -rf "$BACKUP_DIR"
zB="$SANDBOX/zB"
cat > "$zB" <<'EOF'
source $ZSH/oh-my-zsh.sh
# Added from troobit/workscripts setup script
setopt shwordsplit
source $ZSH/oh-my-zsh.sh
alias t='tmux'
EOF
outB="$(migrate_legacy_zshrc "$zB")"
if grep -Fq "# Added from troobit/workscripts setup script" "$zB"; then
  pass "missing end anchor: legacy region NOT deleted"
else
  fail "missing end anchor: legacy region NOT deleted"
fi
if printf '%s' "$outB" | grep -qi "skip"; then
  pass "missing anchor is reported (skip)"
else
  fail "missing anchor is reported (skip)"
fi

echo
if [ "$FAILS" -eq 0 ]; then
  echo "ALL PASS (sync-config-migrate)"
  exit 0
else
  echo "$FAILS FAILURE(S) (sync-config-migrate)"
  exit 1
fi
