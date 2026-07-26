#!/bin/bash
# skup-start-cmd.sh — tests for skup start-command detection (Req 5.3, D7).
# Self-contained and executable. Builds fixture repos under a temp dir and
# checks skup_start_cmd's precedence: declared cmd.<repo> (even empty) wins and
# skips detection; else Makefile `^dev:` -> "make dev"; else package.json
# .scripts.dev -> "pnpm dev"; else "".

set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
SKUP="$DIR/../skup"

PASS=0
FAIL=0
ok()  { echo "  ok   - $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL - $1"; FAIL=$((FAIL + 1)); }
assert_eq() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected [$2], got [$3])"; fi; }

[ -f "$SKUP" ] || { echo "skup not found at $SKUP" >&2; exit 1; }
# shellcheck source=/dev/null
source "$SKUP"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ROOT="$WORK/repos"
mkdir -p "$ROOT"

mk_makefile_dev() { mkdir -p "$ROOT/$1"; printf 'dev:\n\techo dev\n' > "$ROOT/$1/Makefile"; }
mk_makefile_nodev() { mkdir -p "$ROOT/$1"; printf 'build:\n\techo build\n' > "$ROOT/$1/Makefile"; }
mk_pkg_dev() { mkdir -p "$ROOT/$1"; printf '{\n  "scripts": { "dev": "vite" }\n}\n' > "$ROOT/$1/package.json"; }
mk_pkg_nodev() { mkdir -p "$ROOT/$1"; printf '{\n  "scripts": { "build": "vite build" }\n}\n' > "$ROOT/$1/package.json"; }

# Fixtures
mk_makefile_dev sdd-ui                  # Makefile dev -> make dev
mk_pkg_dev rtob                         # package.json dev -> pnpm dev
mk_makefile_dev toes                    # has Makefile dev, but overridden below
mk_makefile_dev brandme                 # has Makefile dev, but declared shell-only below
mkdir -p "$ROOT/finance"                # specs-only, nothing -> ""
mk_pkg_dev web-only                     # only package.json dev -> pnpm dev
mk_makefile_nodev fallthrough && mk_pkg_dev fallthrough   # Makefile without dev -> falls to pnpm
mk_pkg_nodev nada                       # neither dev target nor dev script -> ""

# Config with an override and a declared-empty shell-only entry
CONF="$WORK/skup.conf"
cat > "$CONF" <<EOF
cmd.toes    = make web
cmd.brandme =
EOF
skup_parse_conf "$CONF"

sc() { skup_start_cmd "$1" "$ROOT/$1"; }

assert_eq "Makefile dev -> make dev"            "make dev" "$(sc sdd-ui)"
assert_eq "package.json dev -> pnpm dev"        "pnpm dev" "$(sc rtob)"
assert_eq "override wins over detection"        "make web" "$(sc toes)"
assert_eq "declared empty -> shell-only, no detection" "" "$(sc brandme)"
assert_eq "specs-only repo -> shell-only"       ""         "$(sc finance)"
assert_eq "package.json-only repo -> pnpm dev"  "pnpm dev" "$(sc web-only)"
assert_eq "Makefile without dev falls to pnpm"  "pnpm dev" "$(sc fallthrough)"
assert_eq "no dev target/script -> shell-only"  ""         "$(sc nada)"

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
