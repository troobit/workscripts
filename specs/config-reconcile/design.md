# Design: config-reconcile

## Overview

Adds machine→repo drift reporting to `macos/verify-setup.sh`, plus an adoption path that writes uncaptured state back into the repo. Because adoption may not write files containing control flow (Req 5.2), the Dock, login-item and system-settings data first moves out of `new-mac.sh` into declarative manifests that both `new-mac.sh` and `verify-setup.sh` read.

## Architecture

Three changes, in dependency order:

1. **Extract manifests.** `DOCK_NAMES`/`DOCK_PATHS`, `LOGIN_APPS`, and the `defaults`/`pmset`/`systemsetup` lines become `macos/dock.conf`, `macos/login-items.conf`, `macos/settings.conf`, read by a shared parser.
2. **Add drift detection** to `verify-setup.sh`: one function per category, the exit-code fix (Req 6.2), and full package coverage (Req 6.3).
3. **Add adoption**, gated behind `--adopt`.

### Step 1 is not purely behaviour-preserving

Three behaviour changes are deliberate and each needs its own test — they must not hide inside a refactor:

| Change | Effect | Why |
|---|---|---|
| Dock `defaults` (`new-mac.sh:294-298`) move out of the `command -v dockutil` guard (`:265`) | A machine without dockutil now gets Dock preferences | `verify-setup.sh:62-66` already asserts them unconditionally, so today's behaviour is a latent bug. Req 8.1 also needs them adoptable |
| Downloads folder becomes a `folder` row | None — it still goes to `--section others` after the apps | Ordering within `persistentOthers` is independent of `persistentApps` |
| `defaults write` failures | Uniform policy replaces mixed policy | See "Failure policy" below |

Everything else must be byte-identical in effect, verified by the argv-capture test below.

### Failure policy and command coupling

The extracted commands do not share a failure policy today: the 12 `defaults write` calls are bare, so under `set -e` (`new-mac.sh:4`) any failure aborts an unattended rebuild, while each `pmset`/`systemsetup` call carries its own `|| echo "⚠️ …"`. The apply loop adopts the **warn-and-continue** policy uniformly, matching `new-mac.sh`'s documented section behaviour (a failing section reports and the run continues) and removing the abort risk. This is a behaviour change for the `defaults` half and is listed above.

`killall Finder` (`:229`) and `killall Dock` (`:301`) are coupling the manifest cannot express: settings written without them are not applied. The apply loop runs restarts **once after all rows are applied**, keyed by domain — any `com.apple.finder` row triggers `killall Finder`, any `com.apple.dock` row triggers `killall Dock`. Today's script already restarts once per group, so this preserves the count.

`killall Dock` must move **outside** the `command -v dockutil` guard along with the five Dock `defaults`. Moving the writes out while leaving the restart inside would be a half-fix: a dockutil-less machine would get the preferences written but never applied, and — worse — the `defaults read` assertions would pass while the Dock visibly ignored them. Either both move or neither does.

**Ordering.** The `SYSTEM PREFERENCES` block (`:209-231`) currently runs *before* the `DOCK CONFIGURATION` block (`:233-305`), and both write `com.apple.dock`. Extracting all 12 `defaults` into one loop necessarily picks one position for writes that currently straddle the Dock rebuild. The settings loop runs **after** the Dock rebuild, so the five Dock preferences keep their current relative position (they are written at `:294-298`, after `dockutil` finishes at `:291`); the seven from `:216-228` move later than they are today. They target `com.apple.dock`, `NSGlobalDomain` and `com.apple.finder`, none of which `dockutil` writes, so the reordering is inert. The argv-capture test pins this: the recorded command order is the assertion.

### The `--local` guard

`--local` is the no-sudo, home-only mode (`new-mac.sh:15-19`), and every extracted line currently sits inside `if [ "$LOCAL" != "1" ]` (`:209`-`:452`). The settings apply loop stays **inside that guard**. Placing it outside would make `--local` run `sudo pmset` and system-wide `defaults write`, breaking the mode's contract. The argv-capture test runs in both modes precisely to catch this.

### Existing duplication this resolves

`verify-setup.sh` carries its own hardcoded copies of both lists, independent of `new-mac.sh`:

| List | `new-mac.sh` | `verify-setup.sh` | State |
|---|---|---|---|
| Dock | 16 rows = 14 apps + 2 `SPACER` (`:239-245`), plus Downloads added at `:290` | 14 app names (`:57-59`) | **The 14 app names are identical in content and order.** verify's copy is *incomplete* — it asserts no spacers and no Downloads folder |
| Login items | 6 paths (`:421-428`) | 6 names (`:108`) | Same set, path vs display name |

The lists have **not** drifted in content; the risk is that nothing keeps them in step, and verify silently covers less than `new-mac.sh` applies. Both become readers of one manifest, so coverage follows the data.

### Call-site parity audit

| Site | Role | Needs equivalent | Rationale |
|---|---|---|---|
| `new-mac.sh:239-262` | `DOCK_NAMES`/`DOCK_PATHS` literals | **Replaced** | Becomes `dock.conf` |
| `new-mac.sh:274-287` | Dock build loop | **Yes** | Reads manifest; `SPACER` and skip-if-absent unchanged |
| `new-mac.sh:290` | Downloads folder add | **Yes** | Becomes a `folder` row, still `--section others` |
| `new-mac.sh:421-428` | `LOGIN_APPS` literal | **Replaced** | Becomes `login-items.conf` |
| `new-mac.sh:433-447` | Login item loop | **Yes** | Reads manifest; `basename` derivation unchanged |
| `new-mac.sh:216-228, 294-298` | 12 `defaults write` lines | **Replaced** | Becomes `settings.conf` |
| `new-mac.sh:312-342` | `pmset`/`systemsetup` setters | **Replaced** | Becomes `settings.conf`; the `-getremotelogin` skip generalises to all `systemsetup` rows |
| `new-mac.sh:345-347` | `setrestartpowerfailure` ⇒ `autorestart` fallback chain | **Kept** | A two-command chain is logic, not data; encoding it would put a command in a data file |
| `new-mac.sh:229, 301` | `killall Finder`/`Dock` | **Yes** | Domain-keyed, after the loop, and **outside** the dockutil guard — see below |
| `new-mac.sh:55` | `brew install gh` | **No** | Stays. Runs before `gh auth login` (`:87`); `brew bundle` is at `:186`. Removing it breaks auth on a fresh machine |
| `new-mac.sh:151` | Nerd font cask install | **Yes** | Add `cask "font-droid-sans-mono-nerd-font"` to the Brewfile so Req 1.2 holds; the direct install stays or goes, either way it is no longer uncaptured |
| `verify-setup.sh:57-61` | Hardcoded Dock names | **Yes** | Reads manifest; removes the second copy and closes its coverage gap |
| `verify-setup.sh:65-77` | 10 `defaults read` assertions | **Yes** | Reads manifest; settings-aware assertion (Req 8) |
| `verify-setup.sh:78-97` | `pmset`/`systemsetup` assertions | **Yes** | Reads manifest |
| `verify-setup.sh:107-110` | Hardcoded login-item names | **Yes** | Reads manifest |
| `verify-setup.sh:111-116` | 5-package sample | **Yes** | `brew bundle check` (Req 6.3) |
| `docs/new-mac-guide.md:248-249` | Documents arrays as customisation points | **Yes** | Must point at manifests |
| `specs/mac-env-setup/*`, `CHANGELOG.md` | Historical records | **No** | Describe past state |

`gh` is already in the Brewfile (`Brewfile:11`); only the nerd font is genuinely absent from it.

## Data Models

### Why not positional fields

The obvious format — whitespace-delimited rows, verb first, "at most one space-bearing field and it must be last" — was designed and rejected. It fails three ways, and the first is the one that matters:

1. **The invariant is a human convention, not a structural property.** Nothing detects a future editor adding a field after the path. It parses, and it is wrong.
2. **There is no single parser.** `read` makes only its *last* variable greedy, so a reader with fewer variables than the row has fields silently packs the remainder into the last one. `read -r verb a b c value` on `app /Applications/Brave Browser.app` yields `a=/Applications/Brave`, `b=Browser.app`. Correctness would require a different arity per row kind — five parsers wearing one name.
3. **The output side was unsafe too.** Emitting tab-separated rows corrupts on a tab-bearing path, so the delimiter problem reappeared after parsing.

The constraint is broader than spaces. **Verified on this machine: macOS filenames legally contain spaces, tabs, newlines, `#`, single and double quotes, backslashes, `=`, `$`, `*`, `;`, `[`, `]` — only `/` and NUL are forbidden.** Any format reserving a character must say what happens when a value contains it.

Prior art is consistent about the answer. freedesktop Desktop Entry defines `\s \n \t \r \\`; systemd uses `key = value` with whitespace around `=` ignored and `#` comments; git config — the closest analogue, being hand-edited *and* machine-appended via `git config --add` while holding arbitrary paths — quotes only when needed and forbids raw newlines outright. All of them escape the few characters the line structure cannot carry and leave everything else literal. None of them reserve a delimiter and hope.

### The format

Every non-blank, non-comment line is `key = value`, split on the **first** `=`, both sides trimmed. That is the shape `skup_parse_conf` (`macos/skup:44-70`) already implements and this repo already tests.

**Records.** Each file declares a whitelist of *record-start* keys and *attribute* keys. A record-start line carries the record's primary value; attribute lines that follow belong to it until the next record-start. Order is file order; a repeated key is a list. This is what makes enforcement structural rather than conventional — an unknown key, a missing `=`, an attribute before any record, or a missing required attribute is a **hard error naming `file:line`**, not a silent mis-parse.

**Escaping — the entire rule.** The vocabulary is freedesktop's, unchanged: `\\ \n \r \t \s`. `\` is the only reserved character. The writer escapes `\` always, newline/CR/tab always, and space as `\s` **only when it is the first or last character of the value**. Everything else stays literal: interior spaces, `#`, quotes, `=`, `%`, `$`, `*`, `;`, `[`, `]`. Any other `\X` is a parse error naming `file:line` — as in git config, where "other char escape sequences are invalid".

The dose is deliberate. Escaping every space turns `/Applications/Visual Studio Code.app` into `Visual\sStudio\sCode.app` (or `%20`, or `\040`) and makes the file hostile to the human who edits it — mangling exactly the character macOS paths contain most. Escaping nothing leaves newlines and endpoint whitespace unrepresentable, and endpoint whitespace is worse than unrepresentable: it is *invisible* in review and silently stripped by many editors on save. So escape only what the line structure genuinely cannot carry.

Backslash over percent-encoding — a close call, decided on the decoder. Percent's natural bash implementation is `printf '%b' "${s//\%/\\x}"`, which forks a subshell and needs a sentinel character to survive `$(...)` stripping trailing newlines; a prototype hit exactly that bug and patched it. The backslash decoder is pure parameter expansion with no fork. Prior art agrees as a secondary matter — fstab (`\040`), systemd, git config and Desktop Entry all escape with backslash, and percent appears only where the value is a URL.

Two arguments were tested and discarded rather than used. That `%` is rarer than `\` in filenames does not survive measurement: **across 12,628 real files under `~/Downloads`, `~/Documents`, `~/Desktop` and `~/Pictures`, plus `/Applications`, neither character occurs once.** And that `\t` reads better than `%09` barely matters here, because under endpoint-only escaping a reader will almost never see an escape at all. The honest residual point favours percent: a hand-typed `%` collides only when followed by two hex digits (~1.5% of pairs) against `\` followed by one of five letters (~3.9%). That is the cost of the choice, and it is bounded by every other `\X` being a hard error.

Round-trip verified in `/bin/bash` 3.2.57 across 25 adversarial values plus 4 rejection cases, all passing: interior tab, newline, CR, CRLF, literal backslash, literal `\n` text, `=`, `#`, `[`, quotes, `$*;`, a literal `%`, unicode, the empty string, a value that is a single space (both end-rules fire on one character), and `x\ ` (escape ordering — must yield `x\\\s`, not `x\\s`). The four rejections are `\x`, a lone trailing `\`, `\0`, and `\%`.

**The one accepted corner:** a *hand-typed* value containing `\` followed by `n`, `r`, `t`, `s` or `\` decodes as an escape. Tool-written values are safe — the writer doubles every backslash, verified. Since only `/` and NUL are illegal in a macOS filename this is not impossible, merely vanishingly rare, and the scripts `stat` every path they read, so a mis-decoded path fails immediately rather than silently.

### `macos/dock.conf`

Order is Dock order; repeated keys are normal.

```
# Dock, left to right. Lines are "key = value"; a literal \ is written \\.
app    = /Applications/iTerm.app
app    = /System/Applications/Notes.app
spacer =
app    = /Applications/WhatsApp.app
spacer =
app    = /Applications/Brave Browser.app
folder = ~/Downloads
```

Display name is derived by `basename` minus `.app`. **Verified against all fourteen current app entries** (the other two rows are spacers), including the four with spaces (`System Settings`, `Brave Browser`, `iPhone Mirroring`, `Visual Studio Code`) and the nested `Simulator` path — every one reproduces exactly. This is verified-against-current-data, not a derivable rule: an app whose `CFBundleDisplayName` differs from its filename would break the comparison in `verify-setup.sh`, which matches on the Dock's label. No current entry does.

Dropping the parallel array removes the desync failure mode entirely — one record carries a path, with nothing to fall out of step with. `folder` records go to the `others` section, as `new-mac.sh:290` does today. `~` expands to `$HOME` at read time; nowhere else.

Record-start keys: `app`, `spacer`, `folder`. No attribute keys.

### `macos/login-items.conf`

One `app = <path>` record per item; name derived by `basename`, matching `new-mac.sh:434`. Record-start key: `app`.

### `macos/settings.conf`

The record-start key names the tool and carries its primary field; attributes follow.

```
defaults = com.apple.dock
key      = wvous-br-corner
type     = int
value    = 14

defaults = NSGlobalDomain
key      = AppleHighlightColor
type     = string
value    = 0.752941 0.964706 0.678431 Green

pmset    = -c
key      = displaysleep
value    = 0

systemsetup = -setremotelogin
getter      = -getremotelogin
value       = on
```

Record-start keys: `defaults`, `pmset`, `systemsetup`. Attribute keys: `key`, `type`, `value`, `getter`. Required attributes per kind are declared and enforced — a `defaults` record missing `type` is a `file:line` error, not a silently untyped comparison.

This is more verbose than a positional row, and that is the trade. What it buys: one attribute per line, so changing a value is a one-line diff; no arity to get wrong; and the free-text `value` is always last on its own line, which is now a property of the grammar rather than a rule someone has to remember.

`systemsetup` rows carry a getter as well as a setter because neither is derivable from the other, and because `new-mac.sh:329-334` *skips* the set when the getter already reports on. The apply loop reproduces that check for every `systemsetup` row, generalising the existing special case rather than losing it.

**The autorestart fallback stays in `new-mac.sh`.** `new-mac.sh:345-347` is `systemsetup -setrestartpowerfailure on || sudo pmset -a autorestart 1 || echo …` — a cross-tool fallback chain that switches verb, flag and argument. Encoding it would mean putting a second executable command inside a data file, which is the thing Decision 6 exists to prevent; a manifest that can express "run this, else run that" is a script with extra steps. Its verification is also differently shaped: `verify-setup.sh:96-97` checks it via `pmset -g | grep autorestart`, not a `systemsetup` getter, so no row shape describes the check either. This line is **Kept**, at the cost of that one setting not being adoptable under Req 8.1 — recorded rather than hidden.

### `macos/reconcile-ignore.conf`

```
shipped  = mas
name     = Xcode

shipped  = mas
name     = TestFlight

ignore   = formula
name     = mlx-lm

ignore   = alias
name     = medata
```

Record-start keys `shipped` and `ignore` carry the category; the `name` attribute carries the free text. Category-scoped by construction (Req 4.2) — an `ignore = formula` record cannot suppress an alias of the same name. Exact match on `name` (Req 4.3). The `shipped`/`ignore` split is what makes Req 4.5 implementable: only `ignore` records are reported when they match nothing. All seven Apple apps required by Req 4.6 ship, plus `ignore = function / name = cppr` and `ignore = export / name = PRISMPATH`.

## Components and Interfaces

New file `macos/lib-manifest.sh`, sourced by `new-mac.sh` and `verify-setup.sh`. `verify-setup.sh:213-239` already sources `macos/skup` in a subshell to reuse `skup_parse_conf`, so sharing code across these scripts is established; a dedicated library file is the tidier form of the same pattern.

```
conf_parse FILE RECORD_KEYS ATTR_KEYS CALLBACK
    # RECORD_KEYS / ATTR_KEYS: space-separated whitelists (the file's schema).
    # CALLBACK: invoked once per record with REC_KIND, REC_VALUE, REC_LINE set,
    #           and rec_get / rec_require available for attributes.
    #           Its return value is IGNORED — see mechanic 4.
rec_get     VAR KEY   # decoded attribute into VAR; returns 1 if absent
rec_require VAR KEY   # same, but a hard error naming the record's file:line
conf_append_record FILE KIND VALUE [ATTRKEY ATTRVALUE]...   # the machine writer
```

One engine, four one-line schema declarations. Bash 3.2 throughout: no associative arrays, no `mapfile`, no `eval` on file content. Because the record-start and attribute whitelists are *per file*, the schema catches a class of mistake a global key list cannot — a prototype confirmed `folder` parsing in `dock.conf` and being rejected in `login-items.conf`, from the schema alone with no per-file code.

**Values are never serialised.** This is the half of the original design that was unsafe independently of the format: emitting delimited rows re-creates the delimiter problem, because a decoded value can contain whatever delimiter is chosen. NUL-delimited output is technically sound but forces consumers into `read -d ''` inside pipeline subshells. Instead the parser calls the consumer, passing decoded values as bash strings in memory, where there is no delimiter to collide with.

Six mechanics are mandatory, each verified in `/bin/bash` 3.2.57. Mechanics 4-6 are here because a prototype of this parser shipped bugs 4 and 5 that reasoning alone did not catch; they were found by executing it.

1. **Getters store via `printf -v`, never `$(...)`.** Command substitution strips trailing newlines — measured: `v=$(printf 'x\n\n')` yields `x`. A path ending in a newline would be silently truncated by the very act of returning it.
2. **The callback runs with stdin redirected from `/dev/null`.** The parse loop's stdin *is* the config file. Measured on a 3-record fixture: a callback that reads stdin consumed the rest of the file and the loop saw **1 record instead of 3**. Silent, and baffling to debug.
3. **`while IFS= read -r line || [ -n "$line" ]`**, keeping `skup_parse_conf`'s form. Without the `||` clause a final line lacking a trailing newline is dropped — and that line is precisely the record adoption just appended.
4. **The callback's exit status is discarded.** A callback whose last command is an incidental test — `[ -n "$x" ] && count=$((count+1))` — returns non-zero on the falsy branch. A parser that treats that as "abort" stops iterating partway through a perfectly valid file, silently. Measured in a prototype, where it truncated iteration mid-file. Errors are raised by the record handlers calling `conf_die`, never by a return code.
5. **A trailing CR is stripped from every line before parsing.** A `dock.conf` saved with CRLF endings otherwise appends `\r` to every value, so every path comparison fails while the file looks correct in an editor and in `git diff`. Measured in a prototype. This is unambiguous precisely because of the escape rule: a value that genuinely ends in CR is written `\r`, so a *raw* CR byte can only ever be a line-ending artifact.
6. **Trimming uses parameter expansion, not a subshell.** The `skup_trim` idiom (`read -r s <<< "$1"`) forks per line; replacing it with `${v%%[[:space:]]}`-style stripping is what brought a full four-file parse to **33 ms**.

Counter increments in the callback reach the current shell because `conf_parse` is invoked directly, not through a pipe. The no-pipeline rule below still applies to any loop the caller writes itself.

**Failures are loud.** Unknown key, missing `=`, an attribute before any record, a missing required attribute, or an unknown `\X` escape all abort with `file:line`. The design's earlier "skip the row and continue" policy is retained only for *semantic* problems (an app path that no longer exists), not for *syntactic* ones — a file that does not parse is a file whose meaning is unknown, and the Dock rebuild destroys before it consumes.

### Dock rebuild safety

`new-mac.sh:271` runs `dockutil --remove all` *before* any row is consumed, so a malformed row discovered mid-loop leaves a partially rebuilt Dock. `dock.conf` is therefore validated in full **before** the removal, and the Dock phase aborts without touching the Dock if validation fails. Everywhere else the per-row skip-and-continue policy applies; this is the one place where destruction precedes consumption.

Symlink resolution reuses the portable `while [ -L ]` loop at `macos/skup:16-26`. `readlink -f` is not POSIX and is absent on older macOS.

### Detection and reporting

```
drift_packages           # Req 1
drift_shell              # Req 2
drift_dock               # Req 3.2-3.4
drift_login_items        # Req 3.1
drift_env                # Req 7
allow_match CAT NAME     # 0 if allowlisted
note CAT ITEM [DETAIL]   # one drift line; increments that category's counter
unadoptable CAT ITEM WHY # reported under its category, never planned (Reqs 1.5, 5.8, 7.4)
```

`unadoptable` items **do** count toward their category's total (Req 6.6) — they are genuine drift, and excluding them would make the count disagree with the visible list. They are rendered in the same category block, marked with the reason, and `adopt_plan` skips them.

**`note` never touches `FAIL`.** It is a separate sink from `check`, which is what protects Req 6.2. `check` increments `FAIL`; `note` increments a per-category counter; the script ends `exit $(( FAIL > 0 ))`.

Per-category counts (Req 6.6) use two parallel arrays, `DRIFT_CATS` and `DRIFT_NUMS`, indexed in step — the same bash 3.2 workaround `skup` uses for its config (`macos/skup:29-31`), since associative arrays are unavailable.

#### Counter integrity rules

The `check`/`note` split is only sound if every counter increment happens in the **current** shell. Three rules are mandatory, and each has a measured failure:

1. **Never pipe into a loop that calls `check` or `note`.** In bash the right-hand side of a pipe is a subshell, so its increments are discarded. Measured: `FAIL=0; printf 'a\nb\n' | while read -r x; do FAIL=$((FAIL+1)); done` leaves `FAIL=0`, while `... done < <(printf 'a\nb\n')` leaves `FAIL=2`. Every manifest-driven loop uses process substitution: `while IFS=$'\t' read -r ...; do ...; done < <(manifest_read ...)`.

   This is the highest-consequence rule in the design. The natural idiom `manifest_read settings.conf defaults | while read ...; do check ...; done` would make `exit $(( FAIL > 0 ))` return 0 no matter how many assertions failed — defeating Req 6.2 with the very code written to satisfy it — and would simultaneously make `adopt_gate` read a clean machine, opening the gate on exactly the unconverged machine it exists to block. Two safety properties, one idiom, no visible symptom.

2. **Use `X=$((X + 1))`, never `((X++))`.** `((X++))` evaluates to the pre-increment value, so it returns exit status 1 when `X` is 0 — which aborts under `set -e`.

3. **Do not source `sync-config.sh` to reuse `backup_path`.** That file sets `set -u` at its line 15, which would leak into `verify-setup.sh`, a script not written for it. The helper is copied into `lib-manifest.sh` instead.

`tests/verify-exitcode.sh` asserts rule 1 behaviourally: a fixture with a failing manifest-driven assertion must produce a non-zero exit.

### Package name resolution (Req 1.4)

Directions use different queries (Decision 2), both normalising names first:

- **uncaptured**: `brew leaves`, `brew list --cask`
- **missing**: `brew bundle check --file Brewfile --verbose` — one call, **measured 1.04s**, versus ~15s for 58 sequential `brew list` calls. This is the Req 6.3 mechanism.

Canonical names resolve through a **three-tier ladder, evaluated lazily** — each tier runs only for names the previous tier left unmatched, so a converged machine never reaches tier 2:

| Tier | Source | Cost | Resolves |
|---|---|---|---|
| 1 | `$(brew --cache)/api/formula_aliases.txt` | **4.8KB, grep, ~4ms, no jq** | Version aliases. Contains `python\|python@3.14` verbatim |
| 2 | `$(brew --cache)/api/{formula,cask}.jws.json` + `jq` | 0.56s both files | Renames via `oldnames`/`old_tokens` — `wireshark-app` carries `old_tokens: ["wireshark"]` |
| 3 | Strip trailing `@<version>` and compare | free | Last resort when `jq` or the cache is absent |

Tier 1 handles the common case for the price of a `grep` on a 5KB file, which is why the 32MB parse is not on the default path. Tier 2 is the only thing that can satisfy Req 1.4's rename case — **tier 3 cannot**, so when `jq` or the cache is unavailable, an unmatched pair is reported as a *possible* rename rather than asserted, and Req 1.4 is met conditionally rather than absolutely. The design states this rather than implying full coverage.

The `.payload` field of each `.jws.json` is a JSON *string* requiring a second parse, which is why tier 2 costs 0.56s rather than the 0.34s a single parse of the formula file suggests.

**Coupling risk, stated plainly:** these are Homebrew's internal cache files, not a public interface. The layout does change — the cache already carries a newer `api/internal/packages.*.jws.json` that did not previously exist. The ladder is designed so this degrades rather than breaks: a missing or changed tier-1/tier-2 file drops to the next tier and reports reduced confidence.

**Unqualified `brew info --json=v2` must not be used** — it goes to the network and exceeded 120s in testing. The qualified form `brew info --json=v2 --installed` does run offline (measured 0.77s) and carries the same alias data; it is a viable substitute for tier 2 if the cache layout changes, and is noted here so the ban is not read more broadly than it is meant.

`mas list` output is fixed-width with a right-padded id column (`        0  prism  (0.11.0)`); parsing takes the first whitespace-delimited field as the id, and an id of `0` marks a sideloaded app that no App Store install can satisfy — reported via `unadoptable`.

### Shell drift (Reqs 2, 7)

Two mechanisms, per Decision 8.

**Functions** use runtime provenance: one `zsh -ic` invocation loads `zsh/parameter` and emits `name<TAB>$functions_source[name]`. The invocation's stdout is **not clean** — oh-my-zsh prints a theme banner that differs every run (the theme is `random` per `zshrc.snippet`) and iTerm2 injects escape sequences. Output is therefore delimited by a sentinel line and everything outside it discarded.

Classification is by source path, **tested in this order**; the sequence is load-bearing:

| # | Source path | Classification |
|---|---|---|
| 1 | *empty* | Autoload stub — **excluded** |
| 2 | resolves into the repo checkout (via symlink) | repo-managed — not drift |
| 3 | `$ZSH_CUSTOM/plugins/**`, `$ZSH_CUSTOM/themes/**` | third-party — excluded |
| 4 | `$ZSH_CUSTOM/**` (default `~/.oh-my-zsh/custom`) | machine-local — **drift** (Req 2.6) |
| 5 | `~/.oh-my-zsh/**` | oh-my-zsh — excluded (Req 2.3) |
| 6 | file reached via an already-reported `source` line | excluded — see below |
| 7 | any other file | machine-local — drift (Req 2.1) |

Rule 1 is not an optimisation: **989 of 1126 functions on this machine have an empty `functions_source`**. They are `compinit` autoload stubs (`_git`, `_xset`, …) that have been marked but not loaded. Without this rule the catch-all reports ~989 functions on the first run and the feature is unusable.

Rule 4 must precede rule 5. `$ZSH_CUSTOM` defaults to `~/.oh-my-zsh/custom` — it sits *inside* the oh-my-zsh tree but holds the user's own config, and `~/.zshrc:98` tells the user to put aliases there. A single `~/.oh-my-zsh/**` test would classify user functions as framework code, dropping exactly what Req 2.6 requires. Rule 3 carves back out the two subdirectories that are genuinely third-party — `new-mac.sh:162-169` clones zsh-autosuggestions into `custom/plugins/`.

Rule 6 prevents double-reporting: `~/.iterm2_shell_integration.zsh` defines ten functions here, and Req 7.1 separately reports the `source` line that pulls it in. Reporting both states one fact twice, which Decision 7 exists to prevent. The `source` line is the item; its contents are not mined.

Rule 2 resolves symlinks, because `~/.aliases.zsh` *is* a symlink to `macos/aliases.zsh`; comparing literal paths would misclassify every repo function as machine-local.

**Aliases** have no provenance equivalent and are scanned textually across the Req 2.6 file set: `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, `~/.zlogin`, `$ZSH_CUSTOM/*.zsh`. Textual scanning misses conditionally-defined aliases; accepted, stated, and the reason Req 2.5 claims no winner.

**Conflicts (Reqs 2.4, 2.5)** need a second pass: `functions_source` returns only the *effective* definition, so it cannot by itself reveal that a name is also defined elsewhere. Conflict detection intersects the provenance result with a textual scan of the repo-managed file — if a name is machine-local by provenance but also appears in `macos/aliases.zsh`, it is a conflict, and provenance names the winner (Req 2.4). The loser's body comes from the textual scan. This is the `lorb` case Decision 8 cites.

**Exports and blocks (Req 7)** are scanned from the same file set, excluding assignments the repo already makes. The exclusion source is **two** places, not one: `macos/zshrc.snippet` (which the repo links to `~/.zshrc.workscripts`) *and* the managed-block template inside `sync-config.sh` (the heredoc at `:281-285`), which is where the `~/.local/bin` PATH entry at `:284` actually comes from. Checking only the snippet would report that entry as machine-local drift on every run, since the snippet does not contain it. A machine-local `if`/`fi` or brace block is reported as one item named by its opening line (Req 7.5): the SSH keychain-unlock block is meaningless split apart. The scanner tracks block depth, which is why it is line-oriented rather than a `grep`.

### Dock comparison (Reqs 3.2-3.4)

`dockutil --list` emits tab-separated `name`, `file:// URL`, `section`, `plist`, `bundle-id`. Normalisation: strip `file://`, percent-decode, strip the trailing slash, and map section names — `dockutil --list` reports `persistentApps`/`persistentOthers` while `--add` takes `apps`/`others`. A row with empty name *and* empty URL is a spacer.

Paths are compared as **bytes, with no Unicode normalisation**. The tempting assumption is that APFS normalises to NFD, so both sides should be folded to NFD before comparing. It does not: measured on this machine, a directory created with NFC bytes reads back as those same NFC bytes, while the NFD spelling still *resolves* to it. Normalising would therefore invent differences between a manifest and a Dock that agree. Byte equality is correct, and a path that differs only by normalisation is a real difference worth reporting.

**The Dock has two independent sections.** Order is only meaningful within one, so `persistentApps` is compared against the `app`/`spacer` rows and `persistentOthers` against the `folder` rows, separately.

**Order is compared over the intersection** (Req 3.3), not positionally over the raw lists. This machine has 21 `persistentApps` against 16 manifest rows; a positional diff would report every position after the first uncaptured item as an order difference — dozens of findings from one insertion. Uncaptured items are removed first (they are already reported by Req 3.2), then the remaining common items are compared by relative rank. Only genuine reorderings are reported.

### Adoption flow

`adopt_plan` produces `(file, verb, row, source_item)` writes and is pure — both preview and apply consume it, so the two cannot disagree about what would be written.

**Targets.** Packages → `Brewfile`. Dock → `dock.conf`. Login items → `login-items.conf`. Settings → `settings.conf`. Aliases, functions, exports and `source` lines → `macos/aliases.zsh`, which Req 5.2 permits because it holds only definitions, and an appended definition cannot alter control flow the way an edited array can. `new-mac.sh` is never written.

**`PRISMPATH` and `cppr` must ship in the allowlist.** `verify-setup.sh:203-205` asserts both are *absent* from the repo shell files — they are the skup feature's canonical examples of machine-specific config. Adoption writing either into `aliases.zsh` would turn three existing assertions red, and since `adopt_gate` blocks on divergence, it could jam adoption afterwards. `reconcile-ignore.conf` therefore ships `ignore function cppr` and `ignore export PRISMPATH` alongside the Apple app entries. `PRISMPATH` is independently unadoptable under Req 7.4 (its value points into a user-specific iCloud container), but the allowlist entry is what stops it being offered in the first place.

**Home-relative rewriting (Req 7.3).** Machine-local exports hard-code `/Users/r/…`, and `specs/skup` AC 4.1 forbids machine-specific paths in repo files — a constraint `verify-setup.sh:203-205` already asserts against for this exact class of value. Adoption therefore rewrites a value's leading `$HOME` prefix before writing, and the replacement differs by target because the two file kinds are read by different things: manifests get `~`, which `conf_parse` expands at read time; `aliases.zsh` gets a literal `$HOME`, since it is sourced by the shell.

Only a **prefix** match is rewritten. A home path appearing mid-value is left alone and the item reported unadoptable, because a substring replacement cannot know whether the occurrence is a path root or coincidental text. A value under a user-specific container with no equivalent on another machine — `PRISMPATH` in its iCloud container — is likewise unadoptable under Req 7.4 rather than rewritten. Rewriting is a *representation* change only: the adopted item must resolve to the equivalent path on another machine, and where it cannot, saying so beats writing something that silently resolves elsewhere.

Multi-line items — function bodies, and the Req 7.5 conditional blocks — are appended verbatim to `aliases.zsh` rather than encoded as manifest rows. This is the concrete reason `aliases.zsh` is the target and a flat manifest is not: `md2pdf` and `lorb` are multi-line functions carrying explanatory comments, and no single-line row shape holds them.

**Gate (Req 5.7).** `adopt_gate` refuses, naming the blocking condition:

| Condition | Scope | Test |
|---|---|---|
| A repo-managed item in this category **differs** on the machine | Per category | See the per-category table below |
| Target files dirty | Global | `git diff --quiet -- <target files>`; an untracked new manifest does not block |
| Settings never applied on this machine | Global | Applied-marker file absent (below) |

"Differs" means different things per category, because only settings carry values. Membership categories cannot diverge — an item is present or it is not — so for them the divergence gate is vacuous and only the two global conditions apply:

| Category | Has a `differs` state? | Per-category gate |
|---|---|---|
| Settings (`settings.conf`) | Yes — `check_setting` state `differs` | Blocks when any row differs |
| Dock | No — membership and order only | Vacuous; order differences are reported, not blocking |
| Login items | No — membership only | Vacuous |
| Packages | No — installed or not | Vacuous |
| Shell (aliases, functions, exports) | Yes — a name defined in both places with different bodies (Reqs 2.4, 2.5) | Blocks when a conflict exists for that name |

This is why the gate is per-category rather than global: for three of the five categories there is nothing that *can* divergently disagree, so a global gate would import the settings category's problems into them for no benefit.

**"Converged" means divergence-only, per category — not `FAIL == 0`.** The three failure kinds are not equivalent evidence:

| Kind | Meaning | Blocks? |
|---|---|---|
| **Absent** | Repo declares it, machine lacks it | **No** — says nothing about whether machine state is intent |
| **Differs** | Both present, values disagree | **Yes** — this is exactly the ambiguity the gate exists for |
| **Undeterminable** | `sudo -n` refused, permission ungranted | **No** — evidence of nothing |

A `FAIL == 0` gate would deadlock on day one and could never be unblocked by adopting. Verified on this machine: `brew bundle check` reports seven absent casks, and `sudo -n systemsetup -getremotelogin` already fails at `verify-setup.sh:90-91` before any of this work. Since installing packages is out of scope, the only escapes would be installing five apps the owner does not want or deleting them from the Brewfile. Package absence must not block adopting a Dock entry.

**The applied-marker.** The `--local` case is the one that can destroy config: nothing about the machine distinguishes "Dock deliberately customised" from "Dock never configured", and adopting the latter overwrites the repo's intended Dock with whatever macOS defaulted to. But `LOCAL` is an in-memory variable — **no marker exists today**. One must be created: `new-mac.sh` writes `~/.workscripts-applied` on completing the non-`--local` settings block, and `adopt_gate` refuses when it is absent. This is a small addition to `new-mac.sh`, listed here because the gate's most important condition is otherwise unimplementable.

### Invocation

`verify-setup.sh` has **no argument parsing at all** today. Adoption needs two flags, so a parser is added: `--adopt` produces the preview (Req 5.3's default), and `--adopt --write` performs the write. Preview-then-confirm is expressed as two invocations rather than an interactive prompt, which keeps the script non-interactive and directly testable — a prompt would need a TTY the test harness does not have.

**Idempotency (Req 5.6)** falls out of the plan being a set difference against current manifest contents: an item already present produces no row, so a second run with no new drift yields an empty plan.

**All-or-nothing (Req 5.9).** Each target is written to a sibling temporary path; only when every write succeeds are they moved into place. Backups use the `backup_path` helper **copied** into `lib-manifest.sh` from `sync-config.sh:31-44` — copied, not sourced, per counter-integrity rule 3. `adopt_apply` returns the list of files and entries written, which `adopt_preview` renders identically (Req 5.10).

### Capturing changed system settings (Requirement 8)

Requirement 8 adds no detector, and Req 8.2 forbids reporting these twice. Two things are nonetheless new.

First, the convergence assertions do **not** currently read every repo-managed value: `new-mac.sh` writes **12** `defaults` keys but `verify-setup.sh` asserts only **10**. `wvous-br-modifier` (`new-mac.sh:217`) and `AppleHighlightColor` (`:221`) are written and never checked, so Req 8.1 could never fire for them. Driving the assertions from `settings.conf` closes the gap by construction — every row is asserted — which *adds* two assertions. That is a deliberate coverage increase, and it is one of the reasons Step 1 is not purely behaviour-preserving.

Second, the assertions must **record what they found**, which the current harness cannot do: `check` (`verify-setup.sh:16-23`) takes a description and a command and keeps only pass/fail, discarding the key and the machine value.

A parallel settings-aware assertion is therefore required — `check_setting ROW`, which reads the machine value for a `settings.conf` row, compares type-aware, records `(row, repo_value, machine_value, state)`, and reports through `check` so the exit-code contract is unchanged. State is one of:

| State | Adoption |
|---|---|
| `differs` | Offer the machine value (Req 8.1) |
| `unset` | Not offered — an unset key is not intent (Req 8.5) |
| `undeterminable` | Not offered; reason shown (Req 8.4) |
| `match` | Nothing to do |

**Unset is distinct from differing** (Req 8.5): `defaults read` on a missing key exits non-zero, which today's `check … test "$(defaults read …)" = "14"` collapses into the same ❌ as a wrong value. `check_setting` separates them on exit status.

**Type-aware comparison (Req 8.3)** is required because write and read syntaxes differ — `-bool true` reads back `1`, `-string "clmv"` reads back `clmv`. The manifest carries the type as its own field so the comparator can normalise both sides; without it every boolean reports a permanent difference. Rules: `bool → {true,YES,1} ≡ 1`; `int`/`float` → numeric equality; `string` → literal. `pmset` values are compared numerically and `systemsetup` values by the getter's `on`/`off` output, neither of which carries a type field.

### Report rendering (Req 6.4)

Convergence assertions keep their `✅`/`❌` per-line form. Drift renders as an indented list under a per-category heading, prefixed `~`, with no ✅/❌ marker anywhere in the block — distinguishable at a glance and by `grep`. Each category prints its count, and an explicit "none" line when empty (Reqs 6.5, 6.6). A heading states that drift does not affect the result, so thirty items are not read as thirty failures.

### Performance budget (Req 6.7)

Measured on the calibration machine:

| Operation | Cost |
|---|---|
| `brew leaves` + `brew list --cask`/`--formula` + `mas list` + `dockutil --list` | 0.41s |
| Name resolution tier 1 (`grep` on a 4.8KB file) | ~0.004s |
| `zsh -ic` function enumeration (1126 functions) | 0.09s |
| Parsing all four manifests (prototype, real data) | 0.033s |
| **Drift total, common path** | **≈0.50s** |
| Name resolution tier 2, only when tier 1 leaves names unmatched | +0.56s → ≈1.06s |
| `brew bundle check` (convergence, Req 6.3 — outside the drift budget) | 1.04s |

The lazy ladder is what keeps the common path at half a second: a converged machine never parses the 32MB file. Worst case with tier 2 firing is ≈1.06s against the 2s budget. Remaining unmeasured: the alias/export textual scan (file reads, negligible) and the `osascript` login-item query, which is bounded by the poll-and-kill mechanism above.

## Error Handling

Every detector is independently fallible; one failing never aborts the run or another category.

| Condition | Behaviour |
|---|---|
| `brew` absent | Package category undeterminable; others run (Req 1.7) |
| `mas` absent vs present-but-signed-out | Distinct messages (Req 1.6) |
| `jq` or brew API cache absent | Name resolution degrades to suffix heuristic; renames reported as possible |
| Automation permission not granted | Login items undeterminable, **non-blocking** (Req 3.5) |
| `sudo` unavailable without prompt | That setting undeterminable via `sudo -n`, matching `verify-setup.sh:87` (Req 8.4) |
| Manifest syntactically invalid (unknown key, missing `=`, orphan attribute, missing required attribute, unknown `\X` escape) | **Fatal for that file**, naming `file:line`. A file whose syntax is unknown has unknown meaning, and the Dock rebuild destroys before it consumes |
| Manifest semantically stale (an app path that no longer exists) | Record skipped and named; loop continues — this is the existing `[ -d "$app_path" ]` behaviour |
| Applied command fails | Warn and continue; never aborts under `set -e` |
| Allowlist absent | All drift reported (Req 4.7) |

### Bounding the login-item query (Req 3.5)

The `osascript` login-item query can hang: it triggers a macOS TCC automation consent dialog when not yet granted (recorded in `docs/agent-notes/repo-layout.md:20`).

**`timeout` cannot be used — it does not exist on macOS.** Neither `timeout` nor `gtimeout` is on a stock install, and `coreutils` is not in the Brewfile. AppleScript's own `with timeout` does not help either, because what blocks is a consent dialog in the TCC layer, not a slow Apple event.

The mechanism is therefore run-in-background, poll, and kill: launch `osascript` writing to a temporary file, poll for completion in short sleeps up to a fixed ceiling, and on expiry `kill` the process and report the category undeterminable, naming the Automation permission the user must grant in System Settings. This uses only the shell's own job control, which is present everywhere.

## Testing Strategy

Tests follow the `macos/tests/*.sh` convention: self-contained bash, sandbox `$HOME`, sourcing the script under test via its `BASH_SOURCE != $0` guard. Per Decision 9 they exercise detection functions directly and never parse rendered output.

| Test file | Covers |
|---|---|
| `tests/manifest-parse.sh` | `conf_parse`: comments, blanks, `~` expansion, record/attribute grouping, schema violations all fatal with `file:line`, escape round-trip over the adversarial value set, final line without trailing newline, callback stdin isolation, `printf -v` newline preservation, order preservation |
| `tests/refactor-argv.sh` | The extraction is behaviour-preserving — see below |
| `tests/drift-packages.sh` | Reqs 1.1-1.5 against fixture lists, including alias, rename and `id: 0` cases |
| `tests/drift-shell.sh` | Reqs 2, 7 against a fixture `$HOME`: empty-provenance stubs, `$ZSH_CUSTOM` vs `custom/plugins`, conflicts, blocks |
| `tests/drift-dock.sh` | Reqs 3.2-3.4: percent-decoding, spacers, two sections, order over the intersection |
| `tests/drift-allowlist.sh` | Reqs 4.2-4.6: category scoping, exact match, shipped vs owner-added staleness |
| `tests/adopt.sh` | Reqs 5.3-5.10: preview writes nothing, idempotent re-run, all-or-nothing rollback, per-category gate refusals |
| `tests/verify-exitcode.sh` | Req 6.2: non-zero when an assertion fails, unchanged when only drift is present |

### The refactor test

Data equality — asserting manifest rows equal the former array literals — is the wrong test. It checks the data, while every risk lives in the consuming loops, and it self-invalidates the first time adoption appends a row to `dock.conf`, which is the feature's purpose.

`tests/refactor-argv.sh` is an argv-capture golden test instead. It stubs `dockutil`, `defaults`, `pmset`, `systemsetup` and `killall` onto `$PATH`, each appending its argv to a log, then diffs the logs from before and after the change in both `--local` and normal mode. That catches command ordering, `--section` flags, guard placement, `--local` containment, quoting of paths with spaces, the `systemsetup` skip-when-already-on branch, and the fact that the autorestart fallback chain was left in place — none of which data equality sees. The three deliberate behaviour changes appear as expected diffs and are asserted explicitly rather than passing silently.

**Making the sections runnable is a prerequisite, and it is unscoped work.** `new-mac.sh` defines only two functions in 711 lines (`clone_repo:534`, `install_tool:607`); the Dock, settings and login-item sections are top-level linear code with no entry point, so "run the affected sections" is not possible today. Two ways to get there:

| Approach | Cost |
|---|---|
| Wrap each affected section in a function, and gate the top-level calls behind the `BASH_SOURCE != $0` guard the other scripts already use | A structural change to `new-mac.sh` beyond moving data out — but it is the same guard pattern `sync-config.sh:301` and `skup:233` already use, so it is conventional here |
| Run the whole script under stubs, with network and installer commands also stubbed | No structural change, but the stub surface grows to every command the script runs, and the golden log covers sections this feature does not touch |

The first is chosen: it is smaller in total, and it makes the sections testable for anything later. This is called out as its own task rather than folded into the extraction, because it changes `new-mac.sh`'s structure and must land — and be seen to be behaviour-neutral — before any data moves.

### Property-based testing

Not warranted as a framework; expressed as loops over a generated row table in `tests/manifest-parse.sh`. The valuable property is **round-trip**: a manifest written by the adoption writer must re-read as the rows written. Append-only preservation (Req 5.5) is a three-line assertion and needs no generation.

Generation must not be limited to values the author thought of, which is what defeats hand-written tables. The generator composes values from an adversarial alphabet — leading space, trailing space, two consecutive spaces, embedded tab, embedded newline, CR, empty value, single-space, `#`, `=`, `%`, `[`, single and double quotes, backslash, backslash-then-`n`, backslash-then-space — so the cases that break the format are produced rather than remembered.

Every generated value must round-trip **exactly**: `conf_decode(conf_encode(v)) == v` for all `v`. That is a genuine universal, unlike the earlier design where the property was "rejects the cases it cannot represent" — a property that is satisfied by a parser which rejects everything. The 25-case manual set already verified in `/bin/bash` 3.2.57 seeds the generator's alphabet, and the 4 rejection cases become the negative half of the property: every `\X` outside `{\\, n, r, t, s}` must fail, never decode.

Fixtures for Reqs 1.1-1.5 are static lists, not live `brew` output, so calibration measured on 2026-08-13 stays meaningful after the machine changes.
