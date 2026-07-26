# Decision Log: skup

## Decision 1: Single full spec covering linking, manifest, idempotency, and skup

**Date**: 2026-07-27
**Status**: accepted

### Context

The user's intent spanned two subsystems: replacing `new-mac.sh`'s curl-and-append config model with symlink-based linking (mirroring how `agentic-coding` links into `~/.claude`), and a new command to open a tagged set of work environments. A mid-turn instruction added a third strand: making `new-mac.sh` idempotent so it can uplift poorly configured Macs and be tested locally.

### Decision

Treat all of it as one feature, `skup`, under `specs/skup/`, with the linking/manifest/idempotency work as supporting infrastructure for the headline command.

### Rationale

The strands share the same files (`new-mac.sh`, the shell config) and the same guiding principle (repo as single source of truth). Splitting them would force artificial ordering and duplicate design context.

### Alternatives Considered

- **Two separate specs (linking first, skup later)**: Cleaner boundaries per spec - Rejected because they share `new-mac.sh` edits and the shell-config link surface; coordinating two specs over the same files costs more than it saves.
- **Smolspec**: Lightweight path - Rejected; ~300-500 LOC across 6-8 files with open design decisions exceeds smolspec criteria.

### Consequences

**Positive:**
- One coherent design for the whole "repo is source of truth" model.
- Idempotency and linking are designed together, avoiding a second migration later.

**Negative:**
- Larger spec and task list; longer before first implementation.

---

## Decision 2: Command name and tag model — `skup [tag]`

**Date**: 2026-07-27
**Status**: accepted

### Context

The command needed a name and a lookup model for what a tag opens.

### Decision

Name the command `skup`. It takes an optional tag — feature, meta, project, billing, client, contract, or any ad hoc tag — that maps to a set of repos/work environments defined in a repo-managed config file. Bare `skup` opens a config-designated default set; an unknown tag errors and lists known tags.

### Rationale

A config-driven tag→repo-set map keeps the command data-driven and lets the user add contexts without touching code. A default set makes the zero-argument case useful. Erroring on unknown tags (rather than guessing) avoids surprising launches.

### Alternatives Considered

- **Unknown tag falls back to a repo-name match**: Convenient shorthand - Rejected as implicit magic; the user chose explicit config + clear errors.
- **Bare `skup` only lists, never defaults**: Safer - Rejected; the user wanted a one-step "start my usual work" default.

### Consequences

**Positive:**
- Ad hoc contexts are just config edits.
- Predictable behaviour; no hidden fallbacks.

**Negative:**
- Every context must be declared before first use.

---

## Decision 3: skup result — one tmux session per repo, servers started

**Date**: 2026-07-27
**Status**: accepted

### Context

Needed to fix the observable end state of `skup <tag>`.

### Decision

For each repo in the tag's set, ensure a tmux session named after the repo, with the repo's dev server running in one window and a free shell in another; attach to the first. Reuse existing sessions/servers; switch (not nest) when already inside tmux.

### Rationale

Per-repo sessions match how the user already works (session history shows heavy `make dev` + tmux use) and pre-empt sdd-ui needing its own repo-switching mechanism. Reuse and switch-not-nest keep re-invocation safe.

### Alternatives Considered

- **One session per tag, one window per repo**: Fewer sessions - Rejected; per-repo sessions are easier to navigate and name.
- **Sessions only, no servers**: Simpler - Rejected; starting servers is the point of the command.

### Consequences

**Positive:**
- One command reaches a working, server-running state.

**Negative:**
- Starting many servers at once is resource-heavy; mitigated by reuse.

---

## Decision 4: Idempotent uplift, tested on the current Mac; drift captured into repo

**Date**: 2026-07-27
**Status**: accepted

### Context

`new-mac.sh` must uplift already-configured Macs and be testable locally. The user's live `~/.zshrc` also holds config that never reached the repo (e.g. the `t` tmux alias).

### Decision

`new-mac.sh` converges to the same end state on fresh and drifted machines, migrating old curl-appended blocks to the linked model with a recoverable backup. The current Mac is the test bed. Local-only aliases/functions in daily use are folded into the repo so linked files become the single source of truth; after migration `~/.zshrc` holds only oh-my-zsh boilerplate, machine-specifics, and guarded source lines.

### Rationale

Idempotency is what makes one script serve fresh-install, uplift, and test-locally. Capturing drift closes the loop — otherwise the "single source of truth" is a fiction and linking silently loses the user's real config.

### Alternatives Considered

- **Link new, leave old appended blocks**: Zero risk to current shell - Rejected; leaves duplicate/competing settings and defeats single-source-of-truth.
- **Migrate but test in a VM/throwaway account**: Safer - Rejected; the user wants this Mac as the test bed, and migration keeps a recoverable backup.
- **Link going forward, capture drift ad hoc later**: Less upfront work - Rejected; deferring drift capture leaves the repo incomplete and the next machine wrong.

### Consequences

**Positive:**
- One script for all three use cases; repo genuinely authoritative.

**Negative:**
- Migration logic must handle messy real-world `~/.zshrc` states; requires a reliable backup step.

---

## Decision 5: macOS only; bootstrap paths preserved

**Date**: 2026-07-27
**Status**: accepted

### Context

The user's note mentioned "powershell syncs", and the `macos/` raw-URL paths are load-bearing at bootstrap.

### Decision

Scope this feature to macOS. PowerShell profile linking is a non-goal. `macos/` files may be added but not moved or renamed, and `new-mac.sh` stays curl-bootstrappable on a bare machine.

### Rationale

The workflow-startup value (skup, dev servers, tmux) is macOS/tmux-specific. Preserving bootstrap paths avoids breaking the one-line install documented in `docs/agent-notes/repo-layout.md`.

### Alternatives Considered

- **Include PowerShell profile linking now**: Broader coverage - Rejected; different platform, no tmux, no shared value with skup this cycle.

### Consequences

**Positive:**
- Focused scope; bootstrap stays intact.

**Negative:**
- Windows machines get no benefit yet; noted as a follow-up.

---

## Decision 6: Split the oh-my-zsh rc into a sourceable snippet

**Date**: 2026-07-27
**Status**: accepted

### Context

The requirements review found that `macos/zshrc` is a full oh-my-zsh top-level rc (`export ZSH`, `ZSH_THEME`, `plugins=(...)`, ending in `source $ZSH/oh-my-zsh.sh`). It cannot be symlinked to `~/.zshrc` (oh-my-zsh owns that file) nor sourced whole (that re-runs the oh-my-zsh installer, double-loading). The linked model (Req 1, 4) had no defined home for the theme/plugin/history/alias settings.

### Decision

Extract the sourceable settings (theme selection, plugin list, history and shell options, aliases) into a repo-managed zsh snippet that is safe to `source`. Link and source that snippet from `~/.zshrc`. The oh-my-zsh bootstrap line stays in the machine-local `~/.zshrc`.

### Rationale

This is the only split that gives single-source-of-truth for the settings the user actually edits while respecting oh-my-zsh's ownership of its own bootstrap. It also sidesteps oh-my-zsh's auto-update rewriting a fully-templated `~/.zshrc`.

### Alternatives Considered

- **Keep appending macos/zshrc but wrap in begin/end markers**: Simpler, no snippet split - Rejected; `~/.zshrc` still holds a generated copy rather than a link, so edits don't propagate by `git pull`.
- **Template the whole `~/.zshrc` including the OMZ install line and link it**: Maximal single-source - Rejected; oh-my-zsh's auto-update mode rewrites `~/.zshrc` and would clobber or de-link it.

### Consequences

**Positive:**
- Repo edits to theme/plugins/aliases propagate to every machine by `git pull`.
- No fight with oh-my-zsh's ownership of its bootstrap.

**Negative:**
- Requires carefully separating sourceable settings from the installer line; the snippet must not re-invoke oh-my-zsh.

---

## Decision 7: Start command detected, config may override

**Date**: 2026-07-27
**Status**: accepted

### Context

Requirement 5.3 said "configured start command" while Out-of-Scope said skup "consumes existing `make dev` / `pnpm dev`" — two mechanisms. The neighbouring repos are uniform (`make dev` or `pnpm dev`), but `finance` is specs-only with no server.

### Decision

skup detects the start command: `make dev` when the Makefile has a `dev` target, else `pnpm dev` when `package.json` declares it, else none (shell-only). The tag config may override per repo.

### Rationale

Detection means zero config for the uniform repos, which is most of them. A per-repo override is the escape hatch for anything that doesn't fit the pattern. Shell-only fallback cleanly handles specs-only repos like `finance`.

### Alternatives Considered

- **Config declares every start command explicitly**: Fully explicit, no surprises - Rejected; redundant typing for repos that already follow the `make dev`/`pnpm dev` convention.

### Consequences

**Positive:**
- Adding a conventional repo to a tag needs only its name.

**Negative:**
- Detection rules are another thing to keep correct as repo conventions evolve.

---

## Decision 8: skup restarts a dead server on reuse

**Date**: 2026-07-27
**Status**: accepted

### Context

Requirement 5.7 (original) conflated "session exists" with "server running." A tmux window outlives a crashed or exited dev-server process, so reuse could attach the user to a dead pane.

### Decision

On reuse, when a repo has a start command whose process is not currently running in its window, skup re-issues the start command before attaching. The end state is "servers running for every repo with a start command," regardless of prior state. Ongoing supervision (restart-while-detached, log aggregation) is out of scope — the check is one-shot at invocation.

### Rationale

Convergence to a known-good state is the whole point of the command; attaching to a dead server would defeat it. A one-shot liveness check at invocation is cheap and matches how the command is used (run it, get to work).

### Alternatives Considered

- **Attach as-is, warn**: Least surprising to a running setup - Rejected; leaves the user to restart manually, undermining "one step to a working state."
- **Leave server liveness out of scope**: Simplest - Rejected; the crashed-server case is the most likely real-world reuse failure.

### Consequences

**Positive:**
- skup reliably lands on servers-running whether starting cold or reusing.

**Negative:**
- Requires detecting the start command's process inside its tmux window, which is more than a naive `send-keys`.

---

## Decision 9: Dry-run/local mode plus a verify step

**Date**: 2026-07-27
**Status**: accepted

### Context

The quality gates are `shellcheck` + `bash -n`, which cannot verify idempotency, `~/.zshrc` migration correctness, or any tmux behaviour — exactly the riskiest requirements. The feature had no verification story for them.

### Decision

Require a local mode that runs only the no-sudo steps with no side effects beyond the home directory, and a verify step (extending the existing `macos/verify-setup.sh`) that asserts the converged end state: expected links present and pointing at the repo, no duplicated `~/.zshrc` markers, valid skup config. Verify exits non-zero listing any failed assertion.

### Rationale

An executable check of the end state is the only way to make idempotency and migration testable, and the current Mac is the designated test bed (Decision 4). Extending the existing verifier avoids a parallel script.

### Alternatives Considered

- **Manual test checklist**: Lighter - Rejected; not enforced, easy to skip, and idempotency regressions are silent.
- **Static gates only**: Matches "done is better than perfect" - Rejected; leaves the highest-risk behaviour entirely unverified.

### Consequences

**Positive:**
- Idempotency and migration have an executable pass/fail check.
- Local mode makes the current Mac a safe test bed.

**Negative:**
- The verifier must be kept in sync with the set of linked files and markers.

---

## Decision 10: Requirements approved

**Date**: 2026-07-27
**Status**: accepted

### Context

Requirements went through the design-critic and peer-review-validator cycle (external CLIs were unreachable, so the peer-validator gave a code-grounded single-reviewer adjudication). Findings were folded in and four open decisions resolved (Decisions 6–9).

### Decision

The user approved the requirements and chose to proceed directly to the design phase, without a Prism review pass.

### Rationale

Review findings were addressed in-document; the remaining unknowns (backup naming, tmux process-liveness detection) are design-phase concerns already constrained by acceptance criteria.

### Consequences

**Positive:**
- Design can start from a reviewed, decision-backed requirements set.

**Negative:**
- No asynchronous Prism review of requirements; the user is relying on the inline review.

---

## Decision 11: ~/.zshrc splice-above-oh-my-zsh + anchor-range migration

**Date**: 2026-07-27
**Status**: accepted

### Context

Design review found two blocking mechanism bugs: (1) the managed marker block was specified as an EOF append, but the snippet's `ZSH_THEME`/`plugins` are read by oh-my-zsh at its `source` line, so an EOF append leaves them inert; (2) migration matched the legacy appended block against current `macos/zshrc`, but the live copy is months old and no longer matches byte-for-byte, so an exact-content match would strand a full duplicate (including a second `source oh-my-zsh.sh`).

### Decision

The managed block is always spliced immediately above the first `source $ZSH/oh-my-zsh.sh` line (strip-then-reinsert each run), never appended. Migration deletes the legacy region by anchor range — from the `# Added from troobit/workscripts setup script` marker down to and including the `export PATH="$(brew --prefix python)…"` line — not by content match.

### Rationale

Splice-above is the only position where the snippet's pre-bootstrap settings take effect, and one rule covers both fresh-install and re-run. Anchor-range deletion is robust to any later edit of `macos/zshrc` because it matches two unique script-written boundary lines, not the (drifting) content between them.

### Alternatives Considered

- **EOF append + a second "insert above" step**: as originally drafted - Rejected; self-contradictory and produces inert theme/plugins on fresh installs.
- **Content-match the legacy block against HEAD `macos/zshrc`**: precise when in sync - Rejected; the live copy predates repo edits, so it would never match and would leave duplicates.
- **Freeze `macos/zshrc` as an immutable migration fingerprint**: avoids drift - Rejected; couples an actively-edited file to migration correctness.

### Consequences

**Positive:**
- Theme/plugins apply on every machine; migration survives future `macos/zshrc` edits.

**Negative:**
- Anchor-range deletion assumes the old script's appends were contiguous; a user who inserted lines mid-block loses them (mitigated by the whole-file backup).

---

## Decision 12: Triage drift, not wholesale capture; Brewfile via brew bundle

**Date**: 2026-07-27
**Status**: accepted

### Context

Review found drift capture would duplicate and corrupt config: copying live aliases without removing the originals violates single-source (Req 4.2); `tk` is corrupted (`tmux kill~session ~t`); `PRISMPATH`/`cppr` hard-code `/Users/r` (forbidden by Req 4.1). Separately, `brew bundle --no-lock` no longer exists in modern Homebrew.

### Decision

Triage each drift line: portable ones (`t`, `cld`, `lorb`) move to `aliases.zsh` and are removed from `~/.zshrc`; `tk` is captured in fixed form; machine-specific ones (`PRISMPATH`, `cppr`, `/Users/r` PATH exports, keychain unlock) stay in `~/.zshrc` and are never captured. The Brewfile is installed via `brew bundle` (no `--no-lock`) with `brew bundle check --verbose` producing the failure summary.

### Rationale

Triage is the only way to satisfy both "single source of truth" and "no machine-specific paths in repo." Verify uses content assertions so a corrupted capture can't pass. Dropping `--no-lock` is required — the flag now errors out before installing.

### Alternatives Considered

- **Copy the whole live tail into the repo**: least effort - Rejected; ships corrupted and machine-specific config to every machine.
- **Custom manifest format instead of Brewfile**: full control of failure handling - Rejected; `brew bundle` already continues past failures and `check` summarizes them, matching current behaviour with less code.

### Consequences

**Positive:**
- Repo files are portable and correct; package install works on current brew.

**Negative:**
- Drift triage is a manual implementation-time judgement per line, not an automated sweep.

---

## Decision 13: Design approved

**Date**: 2026-07-27
**Status**: accepted

### Context

The design went through design-critic and peer-review-validator (external CLIs unreachable both times, so the peer pass was a code-grounded single-reviewer adjudication). Nine findings plus two new material ones were folded in (Decisions 11–12 capture the two blockers).

### Decision

The user approved the design and chose to proceed directly to task planning, without a Prism review pass.

### Consequences

**Positive:**
- Task planning starts from a reviewed design with the mechanism-level bugs resolved.

**Negative:**
- External-reviewer corroboration remained blocked; the design rests on the inline single-reviewer passes.

---

## Decision 14: Tasks approved — spec complete

**Date**: 2026-07-27
**Status**: accepted

### Context

An 18-task rune plan was created across two streams (config linking, skup), passing the red/green TDD, requirement-coverage, dependency-acyclicity, and non-goal self-checks.

### Decision

The user approved the task list. The spec (requirements, design, decision log, tasks) is complete and ready for implementation.

### Consequences

**Positive:**
- Implementation can begin from a reviewed, decision-backed plan with parallelizable streams.

**Negative:**
- None noted.

---
