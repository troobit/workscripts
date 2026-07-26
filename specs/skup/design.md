# Design: skup

## Overview

Turn the cloned `workscripts` repo into the single source of truth for a Mac's shell config, and add `skup`, a command that opens a tagged set of repos as tmux sessions with dev servers running. `new-mac.sh` stops copying-and-appending config from GitHub raw URLs and instead delegates to a factored-out, idempotent sync step that links repo files into place.

## Architecture

### New and changed files under `macos/`

All new files go under `macos/` so the existing raw-URL bootstrap can `curl` them; nothing under `macos/` is moved or renamed (Req 6.2).

| File | Role |
|---|---|
| `macos/sync-config.sh` | The idempotent, no-sudo sync step. Links repo files, sources the zsh snippet, migrates old blocks. Callable standalone and from `new-mac.sh`. |
| `macos/zshrc.snippet` | Sourceable oh-my-zsh settings split out of `macos/zshrc` (D6). Linked to `~/.zshrc.workscripts`, sourced from `~/.zshrc`. |
| `macos/Brewfile` | Package manifest (formulae, casks, `mas` apps) replacing the in-script arrays. |
| `macos/skup` | The `skup` command (bash). Linked onto `PATH`. |
| `macos/skup.conf` | Tag → repo-set config (default set + per-repo overrides). |
| `macos/verify-setup.sh` | Extended with a Shell Config / links / skup-config assertion block (Req 3.5). |
| `macos/new-mac.sh` | Package section reads the Brewfile; shell-config section calls `sync-config.sh`; adds `--local` mode (see below). |
| `macos/aliases.zsh` | Gains the captured drift aliases/functions (Req 4). |

### Control flow

```
new-mac.sh (bootstrap or re-run)
  ├─ interactive phase (SSH/gh) ........ skipped when --local
  ├─ sudo phase (system/Dock/power) .... skipped when --local
  ├─ brew bundle --file macos/Brewfile . manifest install (Req 2)
  └─ sync-config.sh ................... links + snippet + migration (Req 1,3,4)

sync-config.sh   (standalone == what new-mac.sh calls; no sudo)
skup [tag]       (independent; consumes skup.conf)
verify-setup.sh  (asserts converged end state)
```

`sync-config.sh` is the single implementation of the linking/migration logic. `new-mac.sh` sources or execs it rather than duplicating steps, so the standalone run and the bootstrap run converge identically (Req 3.7). On a bare machine the bootstrap still works: `new-mac.sh` clones the repo (existing REPOSITORY SETUP section) and then calls the cloned `macos/sync-config.sh`.

### `new-mac.sh --local` (Req 3.4)

`--local` is a home-directory-only, no-sudo mode for testing on the current Mac. It runs only: the Brewfile install and `sync-config.sh`. It **skips** the sections that prompt or need root: the interactive `read` prompts and SSH/`gh auth` phase (new-mac.sh:63-109), `sudo -v` and the background sudo keep-alive loop + EXIT trap (115-126), and every `sudo`/`defaults`/`pmset`/`systemsetup`/Dock/login-item/power/headless section. The `tee -a SETUP.log` logging (145) is home-only and may stay. Gating is a single `LOCAL=1` guard checked at each sudo-requiring section; because `sync-config.sh` is already no-sudo, `--local` is mostly a matter of not entering the interactive and sudo phases.

## Components and Interfaces

### sync-config.sh

```
sync-config.sh [--dry-run]
```

Resolves its own repo dir via `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` (the `sync-claude.sh` pattern). Exits non-zero with a plain message if `macos/` siblings are missing (Req 1.4). No `sudo`, no side effects outside `$HOME`.

Managed-link set (Req 1.1 — this table *is* the complete enumerated set; nothing else is linked):

| Link | Target |
|---|---|
| `~/.aliases.zsh` | `macos/aliases.zsh` |
| `~/.vimrc` | `macos/vimrc` |
| `~/.zshrc.workscripts` | `macos/zshrc.snippet` |
| `~/.local/bin/skup` | `macos/skup` |

`link_file()` helper — the one non-obvious contract is idempotence + write-once backup:

```
link_file SRC DEST:
  if DEST is already a symlink to SRC:        return (no-op, no backup)   # Req 1.3 re-run
  if DEST exists (file or wrong link):        back up to backup_path(DEST), then ln -sfn
  else:                                        ln -sfn SRC DEST
```

`backup_path(DEST)` — write-once, collision-safe, and must avoid `~/.zshrc.bak` (owned by the `removetheme` alias, aliases.zsh:17):

```
base = ~/.workscripts-backups/<basename>.<UTC-timestamp>   # date -u +%Y%m%dT%H%M%SZ
path = base.bak; while [ -e path ]; do path = base.<n++>.bak; done
```

A dedicated backup dir (not a sibling `.bak`) sidesteps the `removetheme` collision entirely. The timestamp plus the collision-avoiding counter makes it truly write-once even for two runs in the same second — an existing backup is never overwritten.

### ~/.zshrc management — markers and migration

The snippet is sourced from `~/.zshrc` via a marked region (Req 3.2). `sync-config.sh` owns exactly this region:

```
# >>> workscripts skup (managed) >>>
[ -f "$HOME/.zshrc.workscripts" ] && source "$HOME/.zshrc.workscripts"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH";; esac
# <<< workscripts skup (managed) <<<
```

The PATH line is guarded (`case`) so it is a no-op when `~/.local/bin` is already on `PATH` — the live `~/.zshrc` already has such an export (line 179, from the DevTools installer), so an unguarded add would be a duplicated block (Req 3.1).

**Ordering constraint (the load-bearing one).** oh-my-zsh reads `ZSH_THEME` and `plugins` when `source $ZSH/oh-my-zsh.sh` runs, so the snippet — which sets `ZSH_THEME=random` and the `plugins=(…)` list — MUST be sourced *before* that line or theme/plugins are inert. The managed block is therefore spliced **immediately above the first `source $ZSH/oh-my-zsh.sh` occurrence**, never appended at EOF. This single splice-above rule governs both the fresh-install (no markers yet) and re-run (markers present) paths:

```
write_managed_block:
  strip any existing managed marker pair (keep content outside it)
  find first line matching `source $ZSH/oh-my-zsh.sh` (or `source "$ZSH"/oh-my-zsh.sh`)
  insert the managed block on the line above it
  if no such line exists (non-omz machine): insert at top of file
```

Because the block is stripped-then-reinserted each run, a re-run is idempotent (one marker pair, same position) and content outside the markers is preserved.

**Migration (Req 3.3).** The legacy state is: a `# Added from troobit/workscripts setup script` marker (new-mac.sh:236) introducing a full copy of the *then-current* `macos/zshrc` (which itself contains a **second** `source $ZSH/oh-my-zsh.sh` and a `ZSH_THEME=random`), then a standalone `source ~/.aliases.zsh` line, then the `export PATH="$(brew --prefix python)…"` line. That copy is months old and will NOT match current `macos/zshrc` byte-for-byte — so migration must not content-match against HEAD. Instead it is **anchor-range deletion**, robust to any later edit of `macos/zshrc`:

1. Back up the whole `~/.zshrc` once via `backup_path` before any edit.
2. Delete the contiguous range from the `# Added from troobit/workscripts setup script` marker line **down to and including** the `export PATH="$(brew --prefix python)…"` line. Both anchors are unique, script-written lines; everything between was appended by the old script in one contiguous block, so this removes the whole legacy region — including its duplicate `source $ZSH/oh-my-zsh.sh` — without touching the user's own later additions. If either anchor is absent (already migrated, or partial), skip deletion and report.
3. Run `write_managed_block` (splice-above), leaving exactly the original machine-local `source $ZSH/oh-my-zsh.sh` (line 75) with the managed block above it.

After this, the machine-local `~/.zshrc` holds the oh-my-zsh bootstrap (`export ZSH`, its default `plugins`, one `source oh-my-zsh.sh`), the user's machine-specific tail (see Drift capture), and the managed block — one source of each setting (Req 4.2).

What lands in `zshrc.snippet` (the sourceable, installer-free settings from `macos/zshrc`, D6): `ZSH_THEME`/`ZSH_THEME_RANDOM_CANDIDATES`, `HYPHEN_INSENSITIVE`, `DISABLE_UNTRACKED_FILES_DIRTY`, `setopt shwordsplit`/`EXTENDED_HISTORY`, `LSCOLORS`, and `plugins=(brew vim-interaction zsh-interactive-cd zsh-navigation-tools)`. The oh-my-zsh bootstrap line stays out of the snippet and machine-local.

### Drift capture (Req 4)

The live `~/.zshrc` tail holds local-only config. It is **triaged**, not copied wholesale — capturing machine-specific paths would violate Req 4.1, and copying without removing the original would duplicate it (Req 4.2). Each captured item is a one-time, reviewed edit to `macos/aliases.zsh` made during implementation (not runtime), and its original line is removed from `~/.zshrc` by the migration:

| Live line | Disposition |
|---|---|
| `alias t='tmux'` | Portable → add to `aliases.zsh`; remove from `~/.zshrc` |
| `alias cld='claude --dangerously-skip-permissions'` | Portable → add to `aliases.zsh`; remove from `~/.zshrc` |
| `alias tk='tmux kill~session ~t '` | **Corrupted** (`~` should be `-`) → add fixed `alias tk='tmux kill-session -t'`; remove broken original |
| `lorb() { nohup orbit … }` | Portable (orbit is a standard tool on these machines) → add to `aliases.zsh`; remove from `~/.zshrc` |
| `export PRISMPATH='/Users/r/…'` | Machine-specific path → **leave in `~/.zshrc`**, do not capture |
| `cppr() { cp "$1" $PRISMPATH; }` | Depends on machine-specific `PRISMPATH` → **leave in `~/.zshrc`** |
| `export PATH=…/Users/r/…` (lmstudio, .local/bin, rune, orbit) | Machine-specific → leave |
| SSH keychain-unlock block, `LESS`, iterm2 integration | Machine-specific → leave |

Removal of the four captured lines is by exact-string match, each guarded and backed up (the whole-file backup from migration step 1 covers them); a line the user has since altered is left and reported rather than clobbered. The verify step asserts these four **resolve to their fixed definitions** (content assertion, not mere definedness — a corrupted `tk` would otherwise pass a definedness check).

### Brewfile manifest (Req 2)

Standard `brew bundle` Brewfile: `brew "x"`, `cask "y"`, `mas "App", id: N`. `new-mac.sh` replaces its `install_packages` arrays with:

```
brew bundle --file "$REPO/macos/Brewfile" || true       # no --no-lock: removed from modern brew
brew bundle check --file "$REPO/macos/Brewfile" --verbose   # lists what remains → the failure summary (Req 2.2)
```

`--no-lock` no longer exists in current Homebrew (verified: `brew bundle --no-lock` errors out before installing anything) — modern `brew bundle` writes no lockfile by default, so the flag is simply dropped. `brew bundle` continues past a failed entry and installs the rest, preserving current behaviour; it exits non-zero if any entry failed, which `|| true` absorbs. The summary is produced by `brew bundle check --verbose` after the run, which names unsatisfied entries. `mas` entries: `brew bundle` skips them with a non-fatal error when the App Store isn't signed in; the run continues (Req 2.4), and the check output names them.

### skup (Req 5)

```
skup [tag]
```

Config `macos/skup.conf` — line-oriented `key = value`, no dependency beyond bash/coreutils:

```
default = sdd-ui rtob siteme
tag.feature = sdd-ui rtob
tag.billing = toes finance
tag.client  = sanarte brandme
cmd.toes    = make web
cmd.brandme =
repos_root  = ~/repos
```

Parsing rules (the non-obvious contracts):

- **Comments** are full-line only (a line whose first non-space char is `#`). There are no inline comments — a `#` after a value is part of the value, so the sample carries none.
- **No `eval`.** Values flow to `tmux send-keys`; the parser reads `key`/`value` by splitting on the first `=` and trimming surrounding whitespace, never evaluating the line. This blocks config-value injection.
- **Tilde**: `~` is expanded only in `repos_root`, via `${v/#\~/$HOME}` (bash does not expand `~` read from a variable). Start commands are not tilde-expanded (they run `cd`'d into the repo).
- **Empty vs missing** (`cmd.brandme =` = explicit shell-only, vs an absent `cmd.<repo>` = auto-detect): the parser records *key presence* separately from value, so `start_cmd` can distinguish "declared empty" from "not declared" (see below).

Resolution: `skup` (no arg) → `default`; `skup X` → `tag.X` or exit 1 listing known tags (Req 5.6/5.7). Repo names resolve under `repos_root`.

Per-repo start command (D7, Req 5.3):

```
start_cmd(repo):
  if cmd.<repo> declared in conf:   use its value (empty value = shell-only, no detection)
  elif Makefile has `^dev:`:        "make dev"
  elif package.json .scripts.dev present:  "pnpm dev"
  else:                             "" (shell-only)
```

The `cmd.<repo> declared` test is key-presence, not value-non-empty — that is why the parser tracks presence separately (above), so `cmd.brandme =` means "shell-only, do not detect" rather than "fall through to detection."

Given the real repos: sdd-ui/siteme/sanarte → `make dev`; rtob → `pnpm dev`; toes → override `make web`; brandme → shell-only; finance → shell-only.

Per repo, in config order (Req 5.4):

```
for repo in tag_set:
  path = repos_root/repo
  if not dir(path): warn "skup: <repo> missing, skipping"; continue    # Req 5.10
  if not has_session(repo):
      tmux new-session -d -s repo -c path -n shell
      if start_cmd: tmux new-window -t repo -n server -c path;
                    tmux send-keys -t repo:server "<start_cmd>" C-m
  else:  # reuse — Req 5.8
      if start_cmd and not server_alive(repo): restart server window
attach_or_switch(first_repo)
```

**Liveness detection** (D8) — the non-obvious contract. A tmux window outlives its command. Detect whether the server is actually running by inspecting the pane's foreground process, not by assuming the window exists:

```
server_alive(repo):
  pid=$(tmux list-panes -t repo:server -F '#{pane_pid}' 2>/dev/null) || return 1
  # any child process of the pane shell == command still running
  pgrep -P "$pid" >/dev/null
```

An idle shell pane has no children → treated as dead → restart re-issues `send-keys` into the existing window (Req 5.8). Since skup creates the server window solely for the start command and runs it in the foreground (`send-keys "make dev" C-m`), a live child means the server is running.

Known limitations (acceptable for the current repos, all of which run foreground dev servers): (a) a server that **daemonizes** — foreground command exits, server backgrounds itself — reads as dead every time, so skup would re-issue the start command and could stack duplicates; (b) if the user runs an unrelated foreground process in the server window, a dead server reads as alive. Both are out of scope (server supervision, per Req Out-of-Scope). `tmux list-panes -t repo:server` is read with `head -1` so a split window yields a single pid.

**Attach vs switch** (Req 5.9): `[ -n "$TMUX" ] && tmux switch-client -t repo || tmux attach -t repo`.

### PATH placement (Req 5.1)

`skup` is linked to `~/.local/bin/skup` → `macos/skup`, and `~/.local/bin` is added to `PATH` inside the managed marker block. `~/.local/bin` is chosen because `agentic-coding`'s bootstrap already uses it for the `rune` symlink, so it is an established convention on these machines.

## Error Handling

| Failure | Behaviour |
|---|---|
| Repo layout missing (sync) | exit non-zero, plain message (Req 1.4) |
| Link target is a user file | back up (write-once) then link, report (Req 1.3) |
| Legacy `~/.zshrc` line user-edited | leave in place, report; do not clobber |
| Brew entry fails | `brew bundle` continues; `check` names it (Req 2.2) |
| App Store not signed in | `mas` entries skipped, run continues (Req 2.4) |
| skup tag unknown | exit 1, list known tags (Req 5.7) |
| skup repo missing on disk | warn, skip, continue (Req 5.10) |
| skup inside tmux | `switch-client`, no nesting (Req 5.9) |

`new-mac.sh` keeps its per-section `|| echo` + summary model (Req 3.6).

**Non-`~/.zshrc` idempotency (Req 3.1).** The existing sections already converge on re-run and this feature does not change them: gitconfig is guarded by `[ ! -f "$HOME/.gitconfig" ]` (new-mac.sh:526), the Dock is rebuilt with `dockutil --remove all` before re-adding (333), and login items are added only when `grep -qi` finds them absent (503). This feature adds no new non-idempotent section; the verify step (below) asserts no duplicate `~/.zshrc` markers as the one new idempotency surface.

## Testing Strategy

Static gates stay (`shellcheck`, `bash -n`) but cannot see idempotency/migration/tmux (decision_log D9). The executable check is `verify-setup.sh`, extended to assert the converged end state (Req 3.5):

- `~/.aliases.zsh`, `~/.vimrc`, `~/.zshrc.workscripts` are symlinks pointing into the repo.
- `~/.zshrc` contains exactly one managed marker pair and sources `~/.zshrc.workscripts`.
- No legacy `# Added from troobit/workscripts setup script` marker remains.
- `~/.local/bin/skup` resolves and is executable.
- `skup.conf` parses and every `default`/`tag.*` repo either exists under `repos_root` or is reported.
- Captured drift present with correct definitions: `t`→`tmux`, `tk`→`tmux kill-session -t` (the fixed form, not the corrupted `~` original), `cld` and `lorb` defined (Req 4.1). Content assertion, since a corrupted alias still "resolves."
- Machine-specific config left in `~/.zshrc`, not captured: `PRISMPATH`/`cppr` still present in `~/.zshrc` and absent from the repo (Req 4.1).

Idempotency is verified behaviourally, the one property worth asserting directly: **run `sync-config.sh` twice; the second run makes no backup and leaves `~/.zshrc` byte-identical to after the first.** A `--dry-run` mode (Req 3.4 local mode) supports checking this on the current Mac without committing changes. No property-based framework applies — the surfaces are shell scripts; the invariant is "second apply == no-op," checked by a diff in the verify step.

Manual acceptance on the current Mac (the test bed, D4): run `sync-config.sh` (migrates live drift), open a new shell (theme/plugins/aliases intact, `t`/`cld` work), run `skup feature` (sdd-ui + rtob sessions, servers up), run it again (reuse, no duplicate sessions), kill a server and re-run (restarted).

## Requirements coverage

Req 1 → sync-config.sh + link table + backup scheme. Req 2 → Brewfile + `brew bundle`/`check`. Req 3 → markers, migration, `--local`, verify extension, per-section summary. Req 4 → aliases.zsh drift capture + snippet split. Req 5 → skup + skup.conf + detection + liveness restart. Req 6 → all files under `macos/`, new-mac.sh clones then calls sync-config.sh.
