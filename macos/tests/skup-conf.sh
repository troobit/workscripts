#!/bin/bash
# skup-conf.sh — tests for the skup.conf parser (Req 5.2).
# Self-contained and executable. Sources macos/skup (which guards its main so
# sourcing only defines functions) and exercises the parser directly.

set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
SKUP="$DIR/../skup"

PASS=0
FAIL=0

ok()   { echo "  ok   - $1"; PASS=$((PASS + 1)); }
bad()  { echo "  FAIL - $1"; FAIL=$((FAIL + 1)); }

assert_eq() { # desc expected actual
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected [$2], got [$3])"; fi
}
assert_true()  { if "${@:2}"; then ok "$1"; else bad "$1"; fi; }
assert_false() { if "${@:2}"; then bad "$1"; else ok "$1"; fi; }

[ -f "$SKUP" ] || { echo "skup not found at $SKUP" >&2; exit 1; }
# shellcheck source=/dev/null
source "$SKUP"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
CONF="$WORK/skup.conf"

cat > "$CONF" <<EOF
# full-line comment, ignored
   # indented full-line comment, also ignored

default = sdd-ui rtob siteme
tag.feature = sdd-ui rtob
cmd.toes    = make web
cmd.brandme =
cmd.hash    = make dev # not a comment
cmd.equals  = a = b
cmd.inject  = \$(touch $WORK/pwned)
cmd.tilde   = ls ~/foo
repos_root  = ~/repos
EOF

skup_parse_conf "$CONF"

# value is text after the first '=', trimmed
assert_eq "default value trimmed" "sdd-ui rtob siteme" "$(skup_conf_get default)"
assert_eq "tag.feature value" "sdd-ui rtob" "$(skup_conf_get tag.feature)"
assert_eq "cmd.toes override trimmed" "make web" "$(skup_conf_get cmd.toes)"

# only full-line '#' are comments; a '#' inside a value is kept
assert_eq "inline hash kept in value" "make dev # not a comment" "$(skup_conf_get cmd.hash)"
assert_false "full-line comment not parsed as key" skup_conf_has "# full-line comment, ignored"

# split on the FIRST '=' only
assert_eq "split on first equals" "a = b" "$(skup_conf_get cmd.equals)"

# no eval: a command-substitution-looking value stays literal and runs nothing
assert_eq "value kept literal, not evaluated" "\$(touch $WORK/pwned)" "$(skup_conf_get cmd.inject)"
assert_false "no eval side effect (pwned file absent)" test -e "$WORK/pwned"

# tilde expanded ONLY for repos_root
assert_eq "tilde NOT expanded in cmd value" "ls ~/foo" "$(skup_conf_get cmd.tilde)"
# shellcheck disable=SC2088  # literal tilde is intentional: the parser stores it raw
assert_eq "raw repos_root value keeps tilde" "~/repos" "$(skup_conf_get repos_root)"
assert_eq "repos_root tilde expanded via helper" "$HOME/repos" "$(skup_repos_root)"

# key-presence recorded separately from empty value
assert_true  "declared-empty key is present" skup_conf_has cmd.brandme
assert_eq    "declared-empty value is empty" "" "$(skup_conf_get cmd.brandme)"
assert_false "absent key is not present" skup_conf_has cmd.nope

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
