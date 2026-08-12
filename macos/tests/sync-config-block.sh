#!/bin/bash
# Tests for write_managed_block() in macos/sync-config.sh (Req 3.2).
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

# shellcheck source=/dev/null
source "$SYNC"

markers_count() { grep -Fc -- "$MANAGED_BEGIN" "$1"; }

# --- Test 1: spliced immediately above first `source $ZSH/oh-my-zsh.sh` ------
z1="$SANDBOX/z1"
cat > "$z1" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=robbyrussell
plugins=(git)
source $ZSH/oh-my-zsh.sh
alias foo=bar
EOF
write_managed_block "$z1" >/dev/null
# The line directly above the first oh-my-zsh source line must be the end marker
line_above="$(grep -n 'source \$ZSH/oh-my-zsh.sh' "$z1" | head -1 | cut -d: -f1)"
prev="$((line_above - 1))"
if [ "$(sed -n "${prev}p" "$z1")" = "$MANAGED_END" ]; then
  pass "block spliced immediately above first oh-my-zsh source line"
else
  fail "block spliced immediately above first oh-my-zsh source line"
fi
if [ "$(markers_count "$z1")" -eq 1 ]; then
  pass "exactly one managed marker pair after first write"
else
  fail "exactly one managed marker pair after first write"
fi

# --- Test 2: strip-then-reinsert is idempotent (byte-identical 2nd run) ------
cp "$z1" "$SANDBOX/z1.after1"
write_managed_block "$z1" >/dev/null
if diff -q "$SANDBOX/z1.after1" "$z1" >/dev/null; then
  pass "second run is byte-identical (idempotent)"
else
  fail "second run is byte-identical (idempotent)"
fi
if [ "$(markers_count "$z1")" -eq 1 ]; then
  pass "still exactly one marker pair after re-run"
else
  fail "still exactly one marker pair after re-run"
fi

# --- Test 3: PATH line is case-guarded (no-op when already on PATH) ----------
guard_line="$(sed -n "/^case /p" "$z1" | head -1)"
BASH_BIN="$(command -v bash)"
if [ -n "$guard_line" ]; then
  # Set HOME/PATH inside the subshell (not via env) so the bash binary itself
  # stays findable. already present -> unchanged; absent -> prepended once.
  out_present="$("$BASH_BIN" -c 'HOME=/tmp/h; PATH="/tmp/h/.local/bin:/usr/bin"; '"$guard_line"'; printf "%s" "$PATH"')"
  out_absent="$("$BASH_BIN" -c 'HOME=/tmp/h; PATH="/usr/bin"; '"$guard_line"'; printf "%s" "$PATH"')"
  if [ "$out_present" = "/tmp/h/.local/bin:/usr/bin" ]; then
    pass "PATH guard is a no-op when ~/.local/bin already on PATH"
  else
    fail "PATH guard is a no-op when ~/.local/bin already on PATH (got: $out_present)"
  fi
  if [ "$out_absent" = "/tmp/h/.local/bin:/usr/bin" ]; then
    pass "PATH guard prepends ~/.local/bin when absent"
  else
    fail "PATH guard prepends ~/.local/bin when absent (got: $out_absent)"
  fi
else
  fail "PATH guard line present in managed block"
fi

# --- Test 4: file with no oh-my-zsh line -> block inserted at top ------------
z2="$SANDBOX/z2"
cat > "$z2" <<'EOF'
export FOO=1
alias baz=qux
EOF
write_managed_block "$z2" >/dev/null
if [ "$(sed -n '1p' "$z2")" = "$MANAGED_BEGIN" ]; then
  pass "no oh-my-zsh line: block inserted at top of file"
else
  fail "no oh-my-zsh line: block inserted at top of file"
fi

# --- Test 5: content outside markers preserved ------------------------------
if grep -Fxq 'export FOO=1' "$z2" && grep -Fxq 'alias baz=qux' "$z2" \
   && grep -Fxq 'alias foo=bar' "$z1" && grep -Fxq 'export ZSH="$HOME/.oh-my-zsh"' "$z1"; then
  pass "content outside markers preserved"
else
  fail "content outside markers preserved"
fi

# --- Test 6: aliases are sourced, and AFTER oh-my-zsh ------------------------
# Regression guard: migrate_legacy_zshrc deletes the legacy
# `source ~/.aliases.zsh` line as part of the anchor range, so the post block
# must reinstate it — below the oh-my-zsh line, since aliases override omz libs.
alias_src='[ -f "$HOME/.aliases.zsh" ] && source "$HOME/.aliases.zsh"'
alias_ln="$(grep -Fxn -- "$alias_src" "$z1" | head -1 | cut -d: -f1)"
omz_ln="$(grep -n 'source \$ZSH/oh-my-zsh.sh' "$z1" | head -1 | cut -d: -f1)"
if [ -n "$alias_ln" ]; then
  pass "aliases source line present after write"
else
  fail "aliases source line present after write"
fi
if [ -n "$alias_ln" ] && [ -n "$omz_ln" ] && [ "$alias_ln" -gt "$omz_ln" ]; then
  pass "aliases sourced AFTER oh-my-zsh (override order preserved)"
else
  fail "aliases sourced AFTER oh-my-zsh (override order preserved)"
fi
if [ "$(grep -Fxc -- "$alias_src" "$z1")" -eq 1 ]; then
  pass "exactly one aliases source line after two runs (idempotent)"
else
  fail "exactly one aliases source line after two runs (idempotent)"
fi
# Non-omz file still gets the aliases line.
if grep -Fxq -- "$alias_src" "$z2"; then
  pass "no oh-my-zsh line: aliases source still added"
else
  fail "no oh-my-zsh line: aliases source still added"
fi

# --- Test 7: full migrate -> write sequence leaves aliases sourced -----------
# The end-to-end order main() uses. Fixture carries the legacy anchor range,
# whose deletion removes the original aliases source line.
z3="$SANDBOX/z3"
cat > "$z3" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# Added from troobit/workscripts setup script
ZSH_THEME=random
source $ZSH/oh-my-zsh.sh
[ -f "$HOME/.aliases.zsh" ] && source "$HOME/.aliases.zsh"
# Prefer Homebrew Python over system Python
export PATH="$(brew --prefix python)/bin:$PATH"
export PRISMPATH='/some/machine/local/path'
EOF
migrate_legacy_zshrc "$z3" >/dev/null
write_managed_block "$z3" >/dev/null
if grep -Fxq -- "$alias_src" "$z3"; then
  pass "migrate+write: aliases still sourced (brup survives migration)"
else
  fail "migrate+write: aliases still sourced (brup survives migration)"
fi
if grep -Fq 'PRISMPATH' "$z3"; then
  pass "migrate+write: machine-local config untouched"
else
  fail "migrate+write: machine-local config untouched"
fi

echo
if [ "$FAILS" -eq 0 ]; then
  echo "ALL PASS (sync-config-block)"
  exit 0
else
  echo "$FAILS FAILURE(S) (sync-config-block)"
  exit 1
fi
