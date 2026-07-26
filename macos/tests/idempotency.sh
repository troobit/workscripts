#!/bin/bash
# Twice-run idempotency test for macos/sync-config.sh (Reqs 3.5, 3.7).
#
# Runs sync-config.sh twice against a sandbox HOME seeded with a drifted
# ~/.zshrc, and asserts the property that matters most: the SECOND run creates
# no new backup and leaves ~/.zshrc byte-identical to after the first run.
#
# Self-contained: operates on a temp HOME, never the real home directory. The
# script is executed as a subprocess (not sourced) so the full main() flow —
# link table, migration, managed-block splice — runs end to end.

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

backup_count() { find "$BACKUP_DIR" -type f 2>/dev/null | wc -l | tr -d ' '; }

# Seed a drifted ~/.zshrc mirroring the live legacy state: an oh-my-zsh
# bootstrap, the curl-appended legacy region (with its own duplicate omz source),
# the four captured drift lines, and machine-specific lines that must survive.
# Single-quoted heredoc keeps $ZSH, $PATH, $(brew...), $1 and the corrupted `tk`
# trailing space literal.
cat > "$HOME/.zshrc" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=random
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Added from troobit/workscripts setup script
setopt shwordsplit
ZSH_THEME=random
plugins=(brew vim-interaction)
source $ZSH/oh-my-zsh.sh
[ -f "$HOME/.aliases.zsh" ] && source "$HOME/.aliases.zsh"
export PATH="$(brew --prefix python)/bin:$PATH"
alias t='tmux'
export PRISMPATH='/Users/r/Prism'
cppr() {
    cp "$1" $PRISMPATH
}
alias cld='claude --dangerously-skip-permissions'
alias tk='tmux kill~session ~t '
lorb() {
    nohup orbit run --tasks-file specs/"$1".md --variants 1 --parallel > /dev/null 2>&1 &
}
EOF

# --- Run 1 -------------------------------------------------------------------
if ! bash "$SYNC" >/dev/null 2>&1; then
  fail "first run exited non-zero"
fi
n1="$(backup_count)"
cp "$HOME/.zshrc" "$SANDBOX/zshrc.after1"

# The first run must have taken a whole-file backup during migration — otherwise
# the "no new backup on re-run" assertion would be vacuous.
if [ "$n1" -ge 1 ]; then
  pass "first run took a backup (migration ran, count=$n1)"
else
  fail "first run took a backup (migration ran, count=$n1)"
fi

# --- Run 2 -------------------------------------------------------------------
if ! bash "$SYNC" >/dev/null 2>&1; then
  fail "second run exited non-zero"
fi
n2="$(backup_count)"

if [ "$n2" -eq "$n1" ]; then
  pass "second run created no new backup (count still $n2)"
else
  fail "second run created no new backup (was $n1, now $n2)"
fi

if diff -q "$SANDBOX/zshrc.after1" "$HOME/.zshrc" >/dev/null; then
  pass "zshrc byte-identical after second run"
else
  fail "zshrc byte-identical after second run"
fi

# Sanity: exactly one managed marker pair survives the second run.
begins="$(grep -Fxc '# >>> workscripts skup (managed) >>>' "$HOME/.zshrc")"
if [ "$begins" = "1" ]; then
  pass "exactly one managed marker pair after second run"
else
  fail "exactly one managed marker pair after second run (found $begins)"
fi

echo
if [ "$FAILS" -eq 0 ]; then
  echo "ALL PASS (idempotency)"
  exit 0
else
  echo "$FAILS FAILURE(S) (idempotency)"
  exit 1
fi
