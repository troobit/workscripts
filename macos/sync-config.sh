#!/bin/bash
# sync-config.sh — idempotent, no-sudo sync of repo-managed shell config into
# the home directory (specs/skup, Reqs 1, 3, 4).
#
# Links the enumerated set of repo files into place, migrates any legacy
# curl-appended ~/.zshrc block to the linked model, and splices a managed
# marker block into ~/.zshrc that sources the repo snippet. Callable standalone
# and from new-mac.sh. No sudo, no side effects outside $HOME.
#
# Usage: sync-config.sh [--dry-run]
#
# Sourcing this file (BASH_SOURCE != $0) exposes its functions without running
# the sync — this is how the tests under macos/tests/ exercise the helpers.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0

MANAGED_BEGIN="# >>> workscripts skup (managed) >>>"
MANAGED_END="# <<< workscripts skup (managed) <<<"

# --- backup_path DEST --------------------------------------------------------
# Print a write-once, collision-safe backup path for DEST under
# ~/.workscripts-backups/. A dedicated backup dir (not a sibling <name>.bak)
# sidesteps the ~/.zshrc.bak owned by the `removetheme` alias. The UTC timestamp
# plus a collision-avoiding counter makes it write-once even for two backups in
# the same second — an existing backup is never returned. Computes only; the
# caller creates the file.
backup_path() {
  local dest="$1"
  local base ts dir path n
  base="$(basename "$dest")"
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  dir="$HOME/.workscripts-backups"
  path="$dir/$base.$ts.bak"
  n=1
  while [ -e "$path" ]; do
    path="$dir/$base.$ts.$n.bak"
    n=$((n + 1))
  done
  printf '%s\n' "$path"
}

# --- link_file SRC DEST ------------------------------------------------------
# Idempotent link with write-once backup (Reqs 1.1, 1.3):
#   - DEST already a symlink to SRC        -> no-op, no backup
#   - DEST exists (file or wrong/broken link) -> back up, then link
#   - DEST absent                          -> link
link_file() {
  local src="$1" dest="$2"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok: $dest already links to $src"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local bp
    bp="$(backup_path "$dest")"
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "[dry-run] would back up $dest -> $bp and link -> $src"
      return 0
    fi
    mkdir -p "$(dirname "$bp")"
    mv "$dest" "$bp"
    echo "backed up $dest -> $bp"
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] would link $dest -> $src"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  echo "linked $dest -> $src"
}

# --- repo layout guard (Req 1.4) --------------------------------------------
# Fail with a plain message if the expected macos/ siblings are missing, i.e.
# the script is not sitting in a proper workscripts/macos checkout.
check_layout() {
  local missing=0 f
  for f in aliases.zsh vimrc zshrc.snippet; do
    if [ ! -f "$SCRIPT_DIR/$f" ]; then
      echo "sync-config: expected file macos/$f not found next to this script" >&2
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    echo "sync-config: repo layout looks wrong — run this from a workscripts/macos checkout" >&2
    return 1
  fi
  return 0
}

# --- link the managed set (Req 1.1) -----------------------------------------
# This list IS the complete enumerated set; nothing outside it is linked.
link_all() {
  link_file "$SCRIPT_DIR/aliases.zsh"   "$HOME/.aliases.zsh"
  link_file "$SCRIPT_DIR/vimrc"         "$HOME/.vimrc"
  link_file "$SCRIPT_DIR/zshrc.snippet" "$HOME/.zshrc.workscripts"
  link_file "$SCRIPT_DIR/skup"          "$HOME/.local/bin/skup"
}

# --- drift line helpers ------------------------------------------------------
# Guarded exact-match removal of a single line. Only an exact whole-line match
# is removed, so a line the user has since altered is left in place.
remove_exact_line() {
  local file="$1" line="$2"
  if grep -Fxq -- "$line" "$file"; then
    grep -Fxv -- "$line" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    echo "  removed drift line: $line"
  else
    echo "  drift line not present (skipped): $line"
  fi
}

# Guarded removal of the exact 3-line lorb() block. Requiring all three lines
# contiguous is the guard — a bare `}` (e.g. cppr's) can never match alone.
remove_lorb_block() {
  local file="$1"
  local l1='lorb() {'
  local l2='    nohup orbit run --tasks-file specs/"$1".md --variants 1 --parallel > /dev/null 2>&1 &'
  local l3='}'
  awk -v a="$l1" -v b="$l2" -v c="$l3" '
    { lines[NR] = $0 }
    END {
      removed = 0
      i = 1
      while (i <= NR) {
        if (removed == 0 && lines[i] == a && lines[i+1] == b && lines[i+2] == c) {
          removed = 1; i += 3; continue
        }
        print lines[i]; i++
      }
      if (removed) print "REMOVED" > "/dev/stderr"
    }
  ' "$file" > "$file.tmp" 2>"$file.lorb"
  if grep -q REMOVED "$file.lorb" 2>/dev/null; then
    mv "$file.tmp" "$file"
    echo "  removed drift block: lorb()"
  else
    rm -f "$file.tmp"
    echo "  drift block not present (skipped): lorb()"
  fi
  rm -f "$file.lorb"
}

# --- migrate_legacy_zshrc [ZSHRC] -------------------------------------------
# Migrate the legacy curl-appended ~/.zshrc to the linked model (Reqs 3.3, 4.2).
# The legacy region is a `# Added from troobit/workscripts setup script` marker
# introducing a months-old copy of macos/zshrc (with its own second
# `source $ZSH/oh-my-zsh.sh`), then a `source ~/.aliases.zsh` line, then the
# `export PATH="$(brew --prefix python)…"` line. Because the copy no longer
# matches macos/zshrc byte-for-byte, deletion is by ANCHOR RANGE, not content
# match: delete from the marker line down to and including the brew-python line.
# The four portable drift lines captured into aliases.zsh are then removed by
# guarded exact match. A whole-file backup is taken once before any edit.
migrate_legacy_zshrc() {
  local zshrc="${1:-$HOME/.zshrc}"
  [ -f "$zshrc" ] || { echo "migration: $zshrc absent, nothing to do"; return 0; }

  local start_marker="# Added from troobit/workscripts setup script"
  local has_range=0
  if grep -Fq -- "$start_marker" "$zshrc" \
     && grep -Fq 'export PATH="$(brew --prefix python)/bin:$PATH"' "$zshrc"; then
    has_range=1
  fi

  # Any captured drift still present?
  local has_drift=0 dl
  for dl in \
    "alias t='tmux'" \
    "alias cld='claude --dangerously-skip-permissions'" \
    "alias tk='tmux kill~session ~t '"; do
    grep -Fxq -- "$dl" "$zshrc" && has_drift=1
  done
  grep -Fq 'lorb() {' "$zshrc" && has_drift=1

  if [ "$has_range" -eq 0 ] && [ "$has_drift" -eq 0 ]; then
    echo "migration: no legacy region or drift found — nothing to do"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] would back up $zshrc and migrate legacy region/drift"
    return 0
  fi

  # Whole-file backup before any edit (covers the range and the drift lines).
  local bp
  bp="$(backup_path "$zshrc")"
  mkdir -p "$(dirname "$bp")"
  cp "$zshrc" "$bp"
  echo "migration: backed up $zshrc -> $bp"

  if [ "$has_range" -eq 1 ]; then
    # Delete the contiguous range: marker line down to and including the first
    # `export PATH="$(brew --prefix python)…"` line after it.
    awk -v s="$start_marker" '
      del == 0 && index($0, s) { del = 1; next }
      del == 1 {
        if ($0 ~ /export PATH="\$\(brew --prefix python\)/) del = 0
        next
      }
      { print }
    ' "$zshrc" > "$zshrc.tmp" && mv "$zshrc.tmp" "$zshrc"
    echo "migration: deleted legacy anchor range"
  else
    echo "migration: legacy anchors not both present — skipping range deletion"
  fi

  # Remove the four captured drift lines (guarded exact match).
  remove_exact_line "$zshrc" "alias t='tmux'"
  remove_exact_line "$zshrc" "alias cld='claude --dangerously-skip-permissions'"
  remove_exact_line "$zshrc" "alias tk='tmux kill~session ~t '"
  remove_lorb_block "$zshrc"
}

# --- write_managed_block [ZSHRC] --------------------------------------------
# Splice the managed marker block into ZSHRC (default ~/.zshrc) so it sources
# the repo snippet and puts ~/.local/bin on PATH (Req 3.2). One rule governs
# both fresh-install and re-run:
#   1. strip any existing managed marker pair (keep content outside it)
#   2. insert the block immediately ABOVE the first `source $ZSH/oh-my-zsh.sh`
#      line, because oh-my-zsh reads ZSH_THEME/plugins (set in the snippet) when
#      that line runs, so an EOF append would leave them inert.
#   3. if there is no such line (non-omz machine), insert at the top.
# Stripping then reinserting each run makes it idempotent: one marker pair, same
# position, byte-identical on the second run. The PATH line is case-guarded so
# it is a no-op when ~/.local/bin is already on PATH (avoids a duplicate block).
write_managed_block() {
  local zshrc="${1:-$HOME/.zshrc}"
  local tmp_block tmp_stripped tmp_out
  tmp_block="$(mktemp)"; tmp_stripped="$(mktemp)"; tmp_out="$(mktemp)"

  cat > "$tmp_block" <<'BLOCK'
# >>> workscripts skup (managed) >>>
[ -f "$HOME/.zshrc.workscripts" ] && source "$HOME/.zshrc.workscripts"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH";; esac
# <<< workscripts skup (managed) <<<
BLOCK

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] would splice managed block into $zshrc"
    rm -f "$tmp_block" "$tmp_stripped" "$tmp_out"
    return 0
  fi

  [ -f "$zshrc" ] || : > "$zshrc"

  # 1. strip any existing managed marker pair.
  awk -v b="$MANAGED_BEGIN" -v e="$MANAGED_END" '
    $0 == b { inblk = 1; next }
    inblk && $0 == e { inblk = 0; next }
    inblk { next }
    { print }
  ' "$zshrc" > "$tmp_stripped"

  # 2/3. splice above first oh-my-zsh source line, else insert at top.
  if grep -Eq '^[[:space:]]*source[[:space:]]+"?\$ZSH"?/oh-my-zsh\.sh' "$tmp_stripped"; then
    awk -v blockfile="$tmp_block" '
      BEGIN { n = 0; while ((getline line < blockfile) > 0) block[n++] = line }
      !done && $0 ~ /^[[:space:]]*source[[:space:]]+"?\$ZSH"?\/oh-my-zsh\.sh/ {
        for (i = 0; i < n; i++) print block[i]
        done = 1
      }
      { print }
    ' "$tmp_stripped" > "$tmp_out"
  else
    cat "$tmp_block" "$tmp_stripped" > "$tmp_out"
  fi

  cat "$tmp_out" > "$zshrc"
  rm -f "$tmp_block" "$tmp_stripped" "$tmp_out"
  echo "managed block written to $zshrc"
}

# --- main --------------------------------------------------------------------
main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      *) echo "sync-config: unknown argument: $1" >&2; return 2 ;;
    esac
    shift
  done

  check_layout || return 1

  link_all
  migrate_legacy_zshrc "$HOME/.zshrc"
  write_managed_block "$HOME/.zshrc"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
