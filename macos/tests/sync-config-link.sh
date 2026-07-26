#!/bin/bash
# Tests for link_file() and backup_path() in macos/sync-config.sh (Reqs 1.1, 1.3).
#
# Self-contained: runs in a temp sandbox with HOME pointed inside it, so it
# never touches the real home directory. Sources sync-config.sh to get the
# functions under test — the script's main() is guarded so sourcing it does
# not run the sync.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC="$SCRIPT_DIR/../sync-config.sh"

FAILS=0
pass() { printf 'ok   - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1"; FAILS=$((FAILS + 1)); }

# --- sandbox -----------------------------------------------------------------
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home"
mkdir -p "$HOME"
REPO="$SANDBOX/repo"
mkdir -p "$REPO"

# shellcheck source=/dev/null
source "$SYNC"

BACKUP_DIR="$HOME/.workscripts-backups"

# --- Test 1: correct existing symlink is a no-op, no backup ------------------
src1="$REPO/aliases.zsh"; printf 'ALIASES\n' > "$src1"
dest1="$HOME/.aliases.zsh"
ln -sfn "$src1" "$dest1"
link_file "$src1" "$dest1" >/dev/null
if [ -L "$dest1" ] && [ "$(readlink "$dest1")" = "$src1" ]; then
  pass "correct symlink preserved"
else
  fail "correct symlink preserved"
fi
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
  pass "no backup created for correct symlink"
else
  fail "no backup created for correct symlink"
fi

# --- Test 2: existing regular file backed up then replaced by link ----------
src2="$REPO/vimrc"; printf 'REPO-VIMRC\n' > "$src2"
dest2="$HOME/.vimrc"
printf 'USER-VIMRC\n' > "$dest2"   # pre-existing downloaded copy
link_file "$src2" "$dest2" >/dev/null
if [ -L "$dest2" ] && [ "$(readlink "$dest2")" = "$src2" ]; then
  pass "regular file replaced by link"
else
  fail "regular file replaced by link"
fi
backup2="$(ls "$BACKUP_DIR"/.vimrc.* 2>/dev/null | head -1)"
if [ -n "$backup2" ] && [ "$(cat "$backup2")" = "USER-VIMRC" ]; then
  pass "original file preserved in backup dir"
else
  fail "original file preserved in backup dir"
fi
if [ ! -e "$HOME/.vimrc.bak" ] && [ ! -e "$HOME/.zshrc.bak" ]; then
  pass "no sibling .bak used (backups live under ~/.workscripts-backups)"
else
  fail "no sibling .bak used (backups live under ~/.workscripts-backups)"
fi

# --- Test 3: same-second second backup gets a numeric counter suffix --------
# Freeze the timestamp so both backups collide on the same base name, proving
# the write-once counter (an existing backup is never overwritten).
date() {
  if [ "${1:-}" = "-u" ]; then printf '20260101T000000Z\n'; else command date "$@"; fi
}
src3="$REPO/thing"; printf 'REPO-THING\n' > "$src3"
dest3="$HOME/.thing"
printf 'ORIGINAL-1\n' > "$dest3"
link_file "$src3" "$dest3" >/dev/null     # first backup
rm -f "$dest3"; printf 'ORIGINAL-2\n' > "$dest3"
link_file "$src3" "$dest3" >/dev/null     # second backup, same second
b1="$BACKUP_DIR/.thing.20260101T000000Z.bak"
b2="$BACKUP_DIR/.thing.20260101T000000Z.1.bak"
if [ -e "$b1" ] && [ -e "$b2" ]; then
  pass "same-second collision produces counter-suffixed backup"
else
  fail "same-second collision produces counter-suffixed backup"
fi
if [ "$(cat "$b1")" = "ORIGINAL-1" ] && [ "$(cat "$b2")" = "ORIGINAL-2" ]; then
  pass "write-once: earlier backup not overwritten"
else
  fail "write-once: earlier backup not overwritten"
fi
unset -f date

# --- summary -----------------------------------------------------------------
echo
if [ "$FAILS" -eq 0 ]; then
  echo "ALL PASS (sync-config-link)"
  exit 0
else
  echo "$FAILS FAILURE(S) (sync-config-link)"
  exit 1
fi
