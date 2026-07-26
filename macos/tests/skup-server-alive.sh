#!/bin/bash
# skup-server-alive.sh — tests for skup liveness detection (Req 5.8, D8).
# Self-contained and executable. server_alive reads the pane pid from
# `tmux list-panes -t <repo>:server -F '#{pane_pid}' | head -1` and treats a
# pane with a live child (pgrep -P) as alive, an idle shell as dead. tmux and
# pgrep are mocked here so no real tmux server is needed.

set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
SKUP="$DIR/../skup"

PASS=0
FAIL=0
ok()  { echo "  ok   - $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL - $1"; FAIL=$((FAIL + 1)); }
assert_alive() { if skup_server_alive "$2"; then ok "$1"; else bad "$1"; fi; }
assert_dead()  { if skup_server_alive "$2"; then bad "$1"; else ok "$1"; fi; }

[ -f "$SKUP" ] || { echo "skup not found at $SKUP" >&2; exit 1; }
# shellcheck source=/dev/null
source "$SKUP"

# Mock tmux: answer list-panes for known repos. "alive" is a split window
# (two pids) to prove head -1 is applied; "gone" has no server window.
tmux() {
  case "$*" in
    "list-panes -t alive:server -F #{pane_pid}") printf '111\n999\n' ;;
    "list-panes -t idle:server -F #{pane_pid}")  printf '222\n' ;;
    "list-panes -t gone:server -F #{pane_pid}")  return 1 ;;
    *) return 1 ;;
  esac
}

# Mock pgrep -P <pid>: only pid 111 has a live child (server running).
pgrep() {
  local pid="$2"
  case "$pid" in
    111) return 0 ;;
    *)   return 1 ;;
  esac
}

assert_alive "pane with a live child is alive" alive
assert_dead  "idle shell pane is dead"         idle
assert_dead  "missing server window is dead"   gone

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
