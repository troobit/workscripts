# Decision Log: config-reconcile

## Decision 1: Extend verify-setup.sh rather than add a standalone reconcile script

**Date**: 2026-08-13
**Status**: accepted

### Context

The workscripts `macos/` tree already has three scripts with distinct jobs: `new-mac.sh` (install and configure), `sync-config.sh` (push repo-managed config into `$HOME`), and `verify-setup.sh` (assert the machine matches the repo). Drift reporting is a fourth job — reading the machine and reporting what the repo does not yet capture — and it needed a home.

The initial recommendation was a standalone `macos/reconcile.sh`, keeping push, verify and reconcile as three separately testable concerns.

### Decision

Extend the existing `macos/verify-setup.sh` with drift reporting instead of adding a new script.

### Rationale

The machine owner chose this after seeing the trade-off. The practical argument is discoverability: a separate script is one more thing to remember to run, whereas drift attached to the verification run appears every time the machine is checked. Measurement supports it — the package, Dock and login-item queries complete in about 0.5s combined warm, so there is no meaningful speed penalty.

### Alternatives Considered

- **Standalone `macos/reconcile.sh`**: Own script, own test file, own exit-code contract - Rejected by the machine owner as another command to remember; the recommendation was made and not taken.
- **Flag on `sync-config.sh` (`--report-drift`)**: Fewer files - Rejected because it puts the repo→machine writer and the machine→repo reader in one script, which confuses what the script is for.

### Consequences

**Positive:**
- Drift is seen on every verification run without a separate habit to form.
- Reuses the existing `check`/`PASS`/`FAIL` output harness.

**Negative:**
- `verify-setup.sh` now answers two different questions — "is this machine converged?" and "is the repo complete?" — which are not the same thing. Req [6.4](requirements.md) exists to keep them visually apart.
- The script grows past its current 242 lines, and its test surface grows with it.
- `verify-setup.sh` is invoked by hand (documented in `docs/new-mac-guide.md` and `docs/new-mac-localhost.md`), not from `new-mac.sh`. Attaching drift to it therefore reaches only people who run it deliberately — a weaker form of the discoverability benefit than assumed when this was decided.

### Impact

Corrected 2026-08-13 after review: an earlier version of this entry claimed `verify-setup.sh` is invoked from `new-mac.sh`. It is not — `new-mac.sh` contains no reference to it. The claimed reuse of an existing invocation was false and has been removed.

---

## Decision 2: Distinct queries and name resolution for package drift

**Date**: 2026-08-13
**Status**: accepted

### Context

Finding packages installed but uncaptured is a set difference between what is installed and what the repo installs. Measuring the obvious implementation on the current machine showed two independent ways it produces false results.

First, `brew leaves` (formulae no other formula depends on) is the right input for the uncaptured direction but useless for the reverse: `podman` is installed yet absent from `brew leaves` because `podman-compose` depends on it.

Second, and separately, package *names* do not match across the boundary. `brew list --formula` prints `python@3.13` and `python@3.14`; there is no formula named `python`, so a plain name diff against the repo's `python` entry reports it missing while simultaneously reporting `python@3.13` as uncaptured — one package, two false findings. The same shape appears with the upstream rename of `wireshark` to `wireshark-app`.

### Decision

Use `brew leaves` to find uncaptured formulae, and resolve names to a canonical identity — collapsing version suffixes and upstream renames — before comparing in either direction.

### Rationale

The two failures have different causes and need different fixes. Dependency suppression is about *which* packages to consider: transitive dependencies are noise when deciding what to capture, since Homebrew installs them automatically. `sqlite`, `ca-certificates`, `openssl@3` and `readline` are all installed, all absent from the manifest, and all correctly suppressed by `brew leaves`.

Name resolution is about *identity*: without it, the most common packages produce paired false positives on every single run, which would dominate the first report and teach the owner to ignore it.

### Alternatives Considered

- **`brew leaves` for both directions**: One query - Rejected because it reports `podman` as missing when it is installed.
- **`brew list --formula` for both directions**: Also one query - Rejected because the uncaptured list would then include every transitive dependency, burying the packages worth capturing.
- **Ignore name mismatches and let the owner allowlist them**: No resolution code - Rejected because it hides a real package behind an exclusion, and the paired false positives recur for every versioned formula added later.

### Consequences

**Positive:**
- Both directions produce correct results, verified against a real machine.
- The uncaptured list stays short enough to act on.

**Negative:**
- Name resolution is a new mechanism with no obvious complete rule; version suffixes and renames are two known cases and others will surface.
- Two queries where a reader might expect one, requiring a comment explaining why they differ.

### Impact

Corrected 2026-08-13 after review: an earlier version of this entry claimed `python` is installed as a transitive dependency. It is not — `python` is an explicit manifest entry (`Brewfile:17`), and the failure is a versioned-alias naming mismatch, a different cause requiring a different fix. Only `podman` is the dependency case.

---

## Decision 3: Drift reporting runs on every verification, not behind a flag

**Date**: 2026-08-13
**Status**: accepted

### Context

Given Decision 1, drift reporting could still be opt-in via a flag so that existing `verify-setup.sh` output stays unchanged for anyone who does not ask for drift.

Timing on the current machine: `brew leaves` plus `brew list --cask` takes 0.55s, `mas list` 0.07s, and `dockutil --list` plus the login-item query 0.27s.

### Decision

Drift reporting runs on every `verify-setup.sh` invocation, with no flag required.

### Rationale

The speed objection does not survive measurement, which removes the main reason to gate it. What remains is that drift only helps if it is seen, and a flag makes being seen conditional on remembering.

### Alternatives Considered

- **Behind a `--drift` flag**: Existing output untouched - Rejected because drift would then only surface when already suspected, defeating the purpose of an unprompted report.
- **Always on, counts only, itemised behind a flag**: Shorter default output - Rejected as a half-measure; counts alone do not tell the owner what to do.

### Consequences

**Positive:**
- Uncaptured config surfaces without anyone deciding to look for it.
- No new flag to document or remember.

**Negative:**
- Output grows on every run, including runs where only convergence was in question.
- A standing report of roughly thirty items invites silencing it wholesale via the allowlist, which would defeat the feature. Req [4.5](requirements.md) (reporting stale owner-added exclusions) is the only counterweight, and it is a weak one.

### Impact

Corrected 2026-08-13 after review: an earlier version justified this by saying an always-on report "cannot break callers such as `new-mac.sh`". `new-mac.sh` does not call `verify-setup.sh`; there are no programmatic callers. The exit-code protection in Req [6.2](requirements.md) stands on its own merit, not on protecting a caller that does not exist.

---

## Decision 4: Adoption may write to all repo surfaces, including executable script code

**Date**: 2026-08-13
**Status**: superseded by Decision 6

### Context

Adoption writes uncaptured items back into the repo. The surfaces differ sharply in risk. `macos/Brewfile` is pure data. The login-item, Dock and `defaults` values live inside `macos/new-mac.sh` as bash arrays and command lines — executable script code.

The recommendation was to restrict adoption to the Brewfile. The machine owner chose all surfaces, accepting the risk on the strength of a preview mode, a backup, and a syntax check that would abandon an invalid write.

### Decision

Superseded. Retained because it records the machine owner's intent — that *every* category be adoptable without hand-transcription — which Decision 6 preserves by a different mechanism.

### Consequences

**Negative:**
- The syntax check this decision relied on was later shown not to detect the failures that matter. See Decision 6.

---

## Decision 5: Allowlist lives in its own repo-managed file

**Date**: 2026-08-13
**Status**: accepted

### Context

Some machine state is deliberately local and must never be reported as drift. Real examples on the current machine are `PRISMPATH` and the `cppr` function, both already treated as machine-specific by the skup feature, plus Apple-supplied App Store apps (Xcode, TestFlight, iWork, GarageBand, iMovie) that would otherwise appear as uncaptured on every Mac.

### Decision

Add `macos/reconcile-ignore.conf`, a repo-managed, line-oriented config file, shipping with default entries for Apple-supplied applications.

### Rationale

A dedicated file keeps drift-ignore rules readable on their own and lets the format follow the line-oriented `key = value` style already established by `skup.conf`, whose parser the project has tested. Keeping it in the repo means an exclusion decided once applies to every machine rebuilt from it.

### Alternatives Considered

- **A section inside `skup.conf`**: Reuses an existing file and parser - Rejected because `skup.conf` maps tmux tags to repo sets; drift exclusions are unrelated and would make the file serve two purposes.
- **Per-machine file outside the repo (`~/.workscripts-ignore`)**: One machine's exclusions never suppress drift on another - Rejected because it is not version-controlled and is lost on exactly the rebuild this repo exists to make reproducible.

### Consequences

**Positive:**
- Exclusions are reviewed, versioned and shared across machines like every other config.
- Apple stock apps never appear as drift, so the App Store category is quiet by default.

**Negative:**
- A repo-wide allowlist can hide genuine drift on a second machine, since an exclusion added for one Mac applies everywhere.
- Requires the shipped-versus-owner-added distinction in Req [4.5](requirements.md), so that a shipped default for absent software does not generate permanent staleness noise.

---

## Decision 6: Adoption writes only declarative data, never executable script code

**Date**: 2026-08-13
**Status**: accepted, supersedes Decision 4

### Context

Decision 4 let adoption write into `macos/new-mac.sh`, relying on requirement 5.7 as drafted: validate the result is syntactically valid, and abandon the change otherwise. Review tested that guard against the corruption shapes an array writer actually produces.

`bash -n` accepted all of: an entry added to `DOCK_NAMES` but not `DOCK_PATHS` (desyncing two parallel arrays so every later Dock app gets the wrong path); an unquoted path containing a space (silently becoming two elements); an entry appended after the closing parenthesis (becoming a command that runs at rebuild time); and a value containing `$` (expanding at runtime to something else). Only an unbalanced parenthesis was caught. `shellcheck` caught one further case. The guard detects roughly one failure mode in six, and none of the ones a writer is likely to cause.

A stronger check was proposed — source the file in a subshell and compare the resulting arrays — and rejected: `new-mac.sh` sets `set -e` and performs top-level side effects including a `curl | bash` Homebrew install, `defaults write` calls and `sudo pmset`. Sourcing it to validate would execute them.

### Decision

Adoption writes only to declarative data files. It never writes executable script code. Requirement [5.2](requirements.md) states this as a constraint on the feature rather than naming a mechanism.

### Rationale

The machine owner's intent in Decision 4 was that every category be adoptable without hand-transcription. That intent is preserved: the constraint does not narrow *what* can be adopted, only *what kind of file* receives the write. Design is free to satisfy it by moving `DOCK_NAMES`, `DOCK_PATHS` and `LOGIN_APPS` out of `new-mac.sh` into data manifests — the move already made for packages, which `new-mac.sh:11-13` documents as the established pattern — while the loops that consume them stay in the script.

The risk profile inverts. A malformed line in a data manifest fails one entry at the point it is read. A malformed array in `new-mac.sh`, under `set -e`, can abort an unattended rebuild of the whole machine.

### Alternatives Considered

- **Keep in-place editing with a semantic check**: Parse the arrays after writing and assert element-wise equality against expectations - Rejected as reintroducing the parse-and-serialise-bash problem the constraint removes; the same fragile parser would both read the list and write it, so a bad write corrupts the input the next run reads.
- **Narrow adoption to the Brewfile and `aliases.zsh`**: Lowest risk - Rejected because it abandons the machine owner's stated requirement that Dock, login items and settings be adoptable too.
- **Keep Decision 4 unchanged**: No rework - Rejected because its safety argument rested on a guard measured to catch one failure mode in six.

### Consequences

**Positive:**
- No adoption write can change program logic, which removes the corruption class entirely rather than trying to detect it.
- Extracting the arrays makes the Dock and login-item lists editable as data, consistent with how packages are already handled.
- The parallel-array desync risk disappears, because a manifest row holds a name and its path together.

**Negative:**
- Requires extracting data out of `new-mac.sh` and writing a parser for the new manifests in bash 3.2 — work this feature would otherwise not do, and a new silent-failure surface. Unlike the Brewfile, there is no third-party parser to inherit.
- Broadens the change surface of a feature that is otherwise additive, touching the script a rebuilt machine depends on most.
- Under Decision 10 the extraction covers not only Dock entries and login items but also the `defaults`, `pmset` and `systemsetup` values, which is most of what `new-mac.sh` currently hard-codes.

### Impact

Replaces requirement 5.7 as originally drafted. Requirement [5.2](requirements.md) now states the constraint; the design phase chooses the mechanism.

---

## Decision 7: The repo→machine direction stays in the convergence assertions

**Date**: 2026-08-13
**Status**: accepted

### Context

The first draft covered both directions: items on the machine the repo lacks, and items in the repo the machine lacks. Review found the second direction is already fully implemented in the same script. `verify-setup.sh` asserts all fourteen Dock entries (lines 57-61), all six login items (lines 108-110) and all ten managed `defaults` keys (lines 65-77). Only the package check is partial — five samples under a header that says so.

Keeping both would print the same fact twice in one run, in two deliberately different visual treatments, with one of them required not to affect the exit code.

### Decision

Cut the repo→machine acceptance criteria. This feature reports machine→repo only. Separately, upgrade the package convergence assertion from a five-package sample to every package the repo installs ([6.3](requirements.md)).

### Rationale

The feature's purpose, stated in its introduction and every user story, is to find what the repo does not yet own. The reverse question is convergence, which `verify-setup.sh` already answers. Removing the overlap eliminates the double-reporting problem and makes the visual distinction in Req [6.4](requirements.md) straightforward instead of contradictory.

The package sample is the one genuine gap and it belongs with the other convergence assertions, not in a drift report.

### Alternatives Considered

- **Keep both, distinguish by presentation**: One comparison engine - Rejected as self-contradictory: Req [6.4](requirements.md) requires drift be visually distinct from assertions, so the same fact cannot have one presentation.
- **Keep everything as drafted**: No rework - Rejected because on the current machine three login items would each appear once as a red assertion failure and again as drift.

### Consequences

**Positive:**
- Removes roughly half of the drafted requirements 1 and 3 without losing any capability.
- Each fact is reported once, in the section that owns it.

**Negative:**
- Upgrading the package assertion to full coverage will turn currently-passing runs red for the five manifest entries this machine lacks (`bluesnooze`, `notunes`, `postman`, `spotify`, `tailscale-app`), which is correct but newly noisy.

### Impact

Refined by Decision 10, which brings `defaults`, `pmset` and `systemsetup` settings back into the feature — but as an adoption capability layered on the existing convergence assertions, not as a second place they are reported. The no-duplicate-reporting principle established here is preserved.

---

## Decision 8: Function drift uses zsh provenance; alias drift does not claim a winner

**Date**: 2026-08-13
**Status**: accepted

### Context

Requirement 2 needs to name definitions that are machine-local rather than repo-managed, while excluding oh-my-zsh's own. Neither obvious approach works alone. A textual scan of `~/.zshrc` never sees an oh-my-zsh alias, making the exclusion criterion dead text, and it cannot tell which of two definitions is in effect. Evaluating an interactive shell sees everything — 107 aliases and 1126 functions on this machine — but was assumed to lose the attribution needed to tell the three sources apart.

That assumption proved false for functions. With `zsh/parameter` loaded, `functions_source` returns the defining file for essentially every function: `cppr` resolves to `~/.zshrc`, `lorb` and `md2pdf` to `~/.aliases.zsh` (a repo symlink), and `omz_urlencode` to `~/.oh-my-zsh/lib/functions.zsh`. zsh exposes no equivalent for aliases.

### Decision

Use runtime provenance for functions, including naming which definition is in effect for a conflict. For aliases, report conflicts by showing both bodies without asserting which one wins.

### Rationale

Provenance makes every part of requirement 2 directly satisfiable for functions — machine-local versus repo-managed versus oh-my-zsh falls out of the source path, with no heuristics. Asymmetric treatment is honest about the fact that zsh gives this for functions and not for aliases.

Claiming a winner for aliases would require modelling source order, which conditional sourcing and `eval` make unreliable. The value is low: no alias is currently defined in both places, whereas the conflict that actually caused a bug was a function (`lorb`, shadowed by a stale copy in `~/.zshrc`).

### Alternatives Considered

- **Textual scan only**: Simple, and it did find all four real machine-local items - Rejected because it cannot detect conflicts or attribute sources, and makes the oh-my-zsh exclusion vacuous.
- **Evaluation with source-order modelling for aliases too**: Uniform treatment - Rejected as the most expensive option in requirement 2, unreliable in the presence of conditionals, and with no current instance to justify it.

### Consequences

**Positive:**
- Function drift, including the shadowing case that caused a real bug, is detected exactly.
- oh-my-zsh definitions are excluded by construction rather than by maintaining a list.

**Negative:**
- Two mechanisms in one requirement, with aliases getting the weaker guarantee.
- Runtime enumeration depends on starting an interactive shell, so anything defined conditionally is only seen when its condition held for that shell.

---

## Decision 9: No machine-readable output mode

**Date**: 2026-08-13
**Status**: accepted

### Context

Review noted the drift report has no programmatic interface: the exit code is reserved for convergence ([6.2](requirements.md)) and the output is decorated human text. That makes the report impossible to assert against cleanly in a test and impossible to script.

### Decision

Do not add a structured output mode. Verify counts in tests against fixtures rather than by parsing the report.

### Rationale

Nothing consumes the output. This is a single-owner repo with no CI gate and no downstream tooling, so a JSON mode would be built for a caller that does not exist. Testing against fixtures — running the detection functions directly with a controlled machine state — is both easier to write and a better test than parsing decorated text.

### Alternatives Considered

- **A `--drift-json` flag**: Makes the report scriptable and testable - Rejected as disproportionate; it adds a second output format to maintain for no current consumer.
- **Make drift affect the exit code**: Free machine-readable signal - Rejected because it breaks Req [6.2](requirements.md): drift is not a failure, and conflating the two makes the exit code useless for its actual purpose.

### Consequences

**Positive:**
- One output format to write and maintain.
- Detection logic stays directly testable, which is where correctness matters.

**Negative:**
- Adoption cannot be scripted or gated on, so "capture drift automatically" is not possible later without adding this.
- Assertions about report content depend on the detection functions rather than the rendered output, so a formatting regression is not caught by tests.

---

## Decision 10: Environment exports and system settings are in scope, by two different mechanisms

**Date**: 2026-08-13
**Status**: accepted

### Context

An earlier draft deferred two categories of machine-local state: environment variables and `PATH` exports in shell config, and the power and remote-access settings applied via `pmset` and `systemsetup`. Both were listed as out of scope to keep the feature small. The machine owner brought both back in after seeing what was being given up.

The two are not the same kind of problem. The shell exports are items the repo has no record of at all — on this machine, `PATH` additions for LM Studio, `rune`, `orbit` and BaseRT, a `LESS` assignment, an iTerm2 integration `source` line, and an SSH keychain-unlock block. The system settings are the opposite: the repo already declares a value for each one and `verify-setup.sh` already asserts it, so nothing is undiscovered — what is missing is a way to say "the machine is right and the repo is stale."

### Decision

Include both. Treat shell exports as a new drift category (requirement [7](requirements.md)). Treat system settings as an adoption capability layered on the existing convergence assertions, reported only by those assertions and never as a second drift category (requirement [8](requirements.md)).

### Rationale

Splitting them this way keeps Decision 7's no-duplicate-reporting principle intact. A setting the repo manages is already reported when it differs; adding a drift entry for it would print the same fact twice, which is exactly what Decision 7 removed. What the owner actually lacked was the ability to act on that report in the machine→repo direction, and that is adoption, not detection.

The exports are genuinely undiscovered, so they need detection, and they are the category most clearly lost on a rebuild — nothing in the repo would recreate them.

### Alternatives Considered

- **Keep both deferred**: Smallest feature - Rejected by the machine owner; these are the items a rebuild silently loses, which is the problem the feature exists to solve.
- **Treat system settings as a drift category like the others**: Uniform handling - Rejected because it reintroduces the double-reporting that Decision 7 cut, for facts the convergence assertions already print.
- **Adopt exports verbatim**: Simplest writer - Rejected because the values hard-code `/Users/r/...`, which `specs/skup` AC 4.1 forbids in repo files; requirement [7.3](requirements.md) requires portable rewriting instead.

### Consequences

**Positive:**
- The categories a rebuild most clearly loses are covered.
- A deliberately changed system setting can be recorded as intent instead of being permanently reported as a failed assertion.

**Negative:**
- Two more requirements and two more detectors, in a feature already spanning six.
- Under Decision 6, adopting system settings means the `defaults`, `pmset` and `systemsetup` values must also move out of `new-mac.sh` into declarative data. That is most of what the script hard-codes, so the extraction is now a substantial refactor rather than a contained one.
- Reading remote-login state needs `sudo`, which the report otherwise avoids entirely; requirement [8.4](requirements.md) keeps it non-blocking at the cost of that setting sometimes being undeterminable.
- Path portability ([7.3](requirements.md)) has no general solution — `$HOME` prefixes rewrite cleanly, but a value like `PRISMPATH` pointing into a user-specific iCloud container does not, so some items stay unadoptable.

---

## Decision 11: Adoption may append to definition-only shell files

**Date**: 2026-08-13
**Status**: accepted, refines Decision 6

### Context

Decision 6 forbade adoption from writing executable script code. Design review found this makes requirement 5.1 unsatisfiable for three of the categories in scope. An adopted alias, function, `PATH` export or `source` line has exactly one plausible home in this repo — `macos/aliases.zsh` — and that file is a zsh script containing shell functions (`lorb`, `md2pdf`), sourced by the login shell. Under the original wording it was off limits, so those categories could be detected but never adopted.

Requirement 5.2 as first written was therefore in direct conflict with requirement 5.1, and neither the requirements review nor Decision 6 caught it.

### Decision

Narrow the constraint: adoption must not write to any file containing control flow. Appending a self-contained definition to a file that holds only definitions is permitted. `macos/aliases.zsh` is an adoption target; `macos/new-mac.sh` is not.

### Rationale

The property that made writing `new-mac.sh` dangerous was never "this file is executable" — it was that an edit could silently change program behaviour. The measured corruptions all worked that way: a desynced parallel array, an entry landing outside a literal and becoming a command, an unquoted path splitting into two elements. `aliases.zsh` has no loops, no conditionals and no commands; an appended `alias x='y'` line either parses or does not, and cannot alter the meaning of a definition above it.

This keeps the constraint pointed at the risk it was written for while letting the feature satisfy requirement 5.1.

### Alternatives Considered

- **Report shell items without adopting them**: Keeps the constraint absolute - Rejected because it reinstates manual transcription for the category that drifts most often, which is the work the feature exists to remove.
- **Generate `aliases.zsh` from a data manifest**: Satisfies both criteria literally - Rejected because a flat manifest cannot hold `md2pdf` or `lorb`, which are multi-line functions with explanatory comments; it would need a hand-written escape hatch, reintroducing the same file by another name.

### Consequences

**Positive:**
- Every category in scope can be adopted, so requirement 5.1 holds.
- The constraint now names the actual hazard, which makes it applicable to files added later.

**Negative:**
- "Contains control flow" is a judgement a script cannot fully make for itself; the set of permitted targets is fixed in the design rather than detected.
- An appended alias can still shadow one defined earlier in the same file. Shadowing is reported (requirement 2.5) but not prevented.

---

## Decision 12: The extraction refactor is verified by argv capture, not data equality

**Date**: 2026-08-13
**Status**: accepted

### Context

Moving the Dock, login-item and settings data out of `new-mac.sh` touches the script an unattended rebuild depends on most, and that script runs under `set -e`. The first design proposed verifying the move by asserting that the manifests reproduce the array literals removed from the script, and by diffing `new-mac.sh --dry-run` output before and after.

Review found both halves unsound. There is no `--dry-run` flag — argument parsing handles only `--local` — so that check would itself have to be built. And data equality tests the data while every risk lives in the consuming loops: whether the settings loop stays inside the `--local` guard, where `killall Finder` and `killall Dock` run, whether a failing row aborts the run under `set -e`, whether the `systemsetup` skip-when-already-on branch survives, and how the two-command fallback at `new-mac.sh:345-347` is expressed. A frozen copy of the literals also self-invalidates the first time adoption appends a row — the feature's whole purpose.

### Decision

Verify with an argv-capture golden test: stub `dockutil`, `defaults`, `pmset`, `systemsetup` and `killall` onto `$PATH` so each records its arguments, run the affected sections before and after the change in both `--local` and normal mode, and diff the logs.

### Rationale

The refactor's contract is that the same commands run with the same arguments in the same order. Capturing argv tests that contract directly, rather than testing a proxy for it. It covers ordering, section flags, guard placement, quoting of the four Dock paths containing spaces, and the branch and fallback cases — and it keeps working after adoption starts appending rows, because it asserts behaviour rather than content.

Running it in both modes is the point: `--local` is a no-sudo contract, and the settings loop landing outside the `if [ "$LOCAL" != "1" ]` guard would break it in a way no data check detects.

### Alternatives Considered

- **Data-equality test on manifest contents**: Simple to write - Rejected as blind to every loop-level risk, and self-invalidating once adoption appends a row.
- **Build `--dry-run` into `new-mac.sh` and diff its output**: Reusable beyond this feature - Rejected as a larger change than the refactor it would verify, and it would still only show what the script says it would do.

### Consequences

**Positive:**
- Tests the property that matters, and keeps testing it after the manifests start changing.
- Forces the three deliberate behaviour changes to be asserted explicitly rather than passing silently.

**Negative:**
- Stubbing five commands onto `$PATH` is more setup than any existing test in `macos/tests/`.
- The golden log must be regenerated whenever the Dock or settings data legitimately changes, which is a maintenance cost the data-equality test would not have had.

---

## Decision 13: Package name resolution uses a lazy three-tier ladder

**Date**: 2026-08-13
**Status**: accepted, refines Decision 2

### Context

Decision 2 established that names must be resolved to a canonical identity before comparing, and the first design read Homebrew's local API cache — `formula.jws.json` (33MB) and `cask.jws.json` (20MB) — with `jq` on every run, measured at 0.56s against a 2s budget.

Review found a far cheaper source that the design had missed: `$(brew --cache)/api/formula_aliases.txt` is **4.8KB of plain `alias|formula` text**, greppable in about 4ms with no `jq` at all, and it contains `python|python@3.14` verbatim — the exact case that motivated the requirement. It does not, however, carry rename data; `wireshark-app`'s `old_tokens` live only in the large JSON.

### Decision

Resolve names through three tiers, evaluated lazily: grep `formula_aliases.txt` first; parse the `.jws.json` files with `jq` only for names tier 1 leaves unmatched; fall back to stripping a trailing `@<version>` when `jq` or the cache is unavailable.

### Rationale

The common case — a versioned alias such as `python` — is resolved for the price of a grep on a 5KB file. The 53MB of JSON is only parsed when something is genuinely unmatched, which on a converged machine is never. That drops the common-path drift total from roughly 1.06s to about 0.50s and leaves real headroom under Req 6.7.

The tiers also degrade in a stated order rather than failing. This matters because these are Homebrew's internal cache files, not a public interface, and the layout does change — the cache already carries a newer `api/internal/packages.*.jws.json` that did not exist before.

### Alternatives Considered

- **Parse the `.jws.json` files on every run**: One mechanism, no tiering - Rejected as spending 0.56s on every run to answer a question a 4ms grep usually answers.
- **`brew info --json=v2 --installed`**: Offline, measured 0.77s, carries the same alias data - Not rejected; recorded as the substitute if the cache layout changes. The unqualified `brew info --json=v2` remains banned because it goes to the network and exceeded 120s.
- **Suffix stripping alone**: No dependency on Homebrew internals at all - Rejected because it cannot resolve renames, so Req 1.4's `wireshark` case would be unmet.

### Consequences

**Positive:**
- Common-path cost falls to about 4ms for name resolution.
- Each tier's loss is a stated reduction in confidence rather than a failure.

**Negative:**
- Three code paths for one question, each needing its own test.
- Req 1.4's rename case is satisfied **conditionally** — only when tier 2 is reachable. Tier 3 reports a possible rename rather than asserting one, and the design says so rather than implying full coverage.

---

## Decision 14: The autorestart fallback chain stays in new-mac.sh

**Date**: 2026-08-13
**Status**: accepted, refines Decision 6

### Context

The extraction moves the `defaults`, `pmset` and `systemsetup` settings into `settings.conf`. One line does not fit: `new-mac.sh:345-347` is `sudo systemsetup -setrestartpowerfailure on || sudo pmset -a autorestart 1 || echo …`, a fallback chain that switches tool, flag and argument between its two branches. An earlier draft invented a `sysfallback` verb carrying a literal fallback command after a `|` separator.

### Decision

Leave those three lines in `new-mac.sh`. Do not add a manifest verb for them.

### Rationale

A row containing `pmset -a autorestart 1` is an executable command sitting in a data file. Decision 6 exists precisely to keep commands out of files that adoption writes, and a format that can express "run this, else run that" is a script with extra steps. Its verification is differently shaped too: `verify-setup.sh:96-97` checks the result via `pmset -g | grep autorestart` rather than a `systemsetup` getter, so no row shape describes the check either.

### Alternatives Considered

- **A `sysfallback` verb with an embedded fallback command**: Keeps every setting adoptable - Rejected as reintroducing executable content into a data file, which is the hazard Decision 6 was written for.
- **Split it into two independent rows**: Fits the existing format - Rejected because the second command must run *only* when the first fails; two unconditional rows would always run both.

### Consequences

**Positive:**
- The manifest format stays declarative, with no conditional or command-bearing rows.
- No new verb for a single line.

**Negative:**
- The restart-after-power-failure setting cannot be adopted under Req 8.1, so that one setting stays hand-edited. Recorded rather than hidden.
- One extracted category is now split across two places, which a future reader must notice.

---

## Decision 15: `key = value` records with minimal backslash-escaping, replacing positional fields

**Date**: 2026-08-13
**Status**: accepted, supersedes the data model in Decision 6's design

### Context

The first data model used whitespace-delimited rows — a verb, then positional fields — governed by the documented invariant "at most one field per row may contain spaces, and it must be the last field". Review of the data model found the invariant unsound in three independent ways.

It is a human convention with nothing enforcing it: an editor adding a field after the path produces a file that parses and is wrong. It cannot be served by one parser, because `read` makes only its last variable greedy, so a reader with fewer variables than the row has fields silently packs the remainder into the last one — `read -r verb a b c value` on `app /Applications/Brave Browser.app` yields `a=/Applications/Brave`. And the output side was unsafe independently of the input side: the parser emitted tab-separated rows, which corrupt on a tab-bearing path.

The constraint is also broader than spaces. Verified on this machine: macOS filenames legally contain spaces, tabs, newlines, `#`, single and double quotes, backslashes, `=`, `$`, `*`, `;`, `[` and `]`. Only `/` and NUL are forbidden.

### Decision

Every manifest is `key = value`, one per line, split on the first `=`. Each file declares a whitelist of record-start keys and attribute keys; a record-start line carries the primary value and subsequent attribute lines belong to it. `\` is the only reserved character, with freedesktop's vocabulary `\\ \n \r \t \s`: the writer escapes `\`, newline, CR and tab always, plus space as `\s` only when it is the value's first or last character. Any other `\X` is a parse error. Values reach consumers through a callback with decoded strings in variables, never through a serialised delimited line.

### Rationale

Three surveyed formats solve exactly this problem — hand-edited, machine-appended, holding arbitrary paths. freedesktop Desktop Entry defines `\s \n \t \r \\`; systemd uses `key = value` with whitespace around `=` ignored; git config, the closest analogue since `git config --add` appends in place, quotes only when needed and forbids raw newlines. All escape the few characters the line structure cannot carry and leave the rest literal. None reserve a delimiter and rely on values not containing it.

Minimal escaping is the deliberate dose. Escaping every space turns `/Applications/Visual Studio Code.app` into `Visual\sStudio\sCode.app`, mangling in review the character macOS paths contain most. Escaping nothing leaves newlines unrepresentable and endpoint whitespace worse than unrepresentable — invisible in a diff and stripped by many editors on save. Escaping only `\`, newline, CR, tab and endpoint space keeps the common path literal while making every legal value representable.

Backslash rather than percent-encoding, on two grounds. `\t` is self-describing where `%09` requires the reader to know ASCII hex; and the prior art is unanimous, with fstab (`\040`), systemd, git config and Desktop Entry all escaping with backslash while percent appears only where values are URLs. The obvious counter — that `%` is rarer than `\` in filenames, so reserving it costs less — was tested and does not hold: across 12,628 real files under `~/Downloads`, `~/Documents`, `~/Desktop`, `~/Pictures` and `/Applications`, neither character occurs once. With the collision cost measured at zero either way, familiarity decides.

The schema whitelist is what converts the old convention into a structural property. A wrong key, a missing `=`, an orphan attribute or a missing required attribute is a hard error naming `file:line`, so the failure mode a positional format made silent is now loud.

An independent prototype executed six candidate formats against 60 single-value and 80 multi-attribute fixtures in real bash 3.2.57. It confirmed the shape decided here — `key = value` split on the first `=`, values escaped — at **0 silent corruptions on the multi-attribute track and 0 on the machine-write path**, against 30 and 4 for the positional format this decision replaces. Its residual 3 are all hand-edit cases. Its own table appears to rank percent-escaping above backslash-escaping, but that comparison is not applicable: its backslash candidate was a *whitespace-delimited* format that had to escape every space, so `\s` was frequent and collided often. Under the `=`-delimited shape adopted here, escapes appear only at value endpoints and the two alphabets sit on the same row of that table.

Round-trip was verified in `/bin/bash` 3.2.57 across 25 adversarial values and 4 rejection cases, all passing. The set includes two that break naive implementations: a value that is a single space, where both the leading and trailing rules fire on the same character, and `x\ `, where escaping in the wrong order yields `x\\s` (decoding to a literal `s`) instead of `x\\\s`.

### Alternatives Considered

- **Keep positional fields with the documented invariant**: No rework - Rejected; the invariant is unenforceable, the single parser does not exist, and the tab-separated output corrupts independently.
- **Single-split `verb rest-of-line`**: Simplest possible - Rejected as strictly worse than `key = value`: it still trims endpoint whitespace with no visible delimiter to anchor the value, `settings.conf` needs multi-attribute records so stanzas reappear anyway, and a mistyped verb parses silently. `=` is a better split point than the first space — visible, and rare in identifiers.
- **Full escaping over a delimited format** (tab-delimited, or percent-encode everything): Structurally sound - Rejected on human cost: a tab delimiter is invisible in review and converted by editors, and encoding every space makes the common path unreadable. Right mechanism, wrong dose; its mechanism is adopted minimally instead.
- **Percent-encoding (`%XX`) as the escape mechanism**: One reserved character, uniform two-hex-digit encoding, and a genuinely narrower collision window — a hand-typed `%` only collides when followed by two hex digits, roughly 1.5% of character pairs, against 3.9% for `\` followed by one of `\nrts` - Rejected, but closely, and the margin is smaller than the surrounding prose first claimed. The usual argument for `%` is that backslashes are common in filenames; that is false here — neither `%` nor `\` occurs in 12,628 real files. What decides it is the decoder: percent's natural implementation is `printf '%b' "${s//\%/\\x}"`, which needs a subshell and a sentinel character to survive `$(...)` stripping trailing newlines (a bug a prototype hit and had to patch), while the backslash decoder is pure parameter expansion with no fork at all. Familiar vocabulary is a secondary tiebreak.
- **`[kind]` section headers with all fields as attributes** (INI/systemd shape, produced independently by the format prototype): No record-start/attribute key distinction to declare, so the schema is purely structural - Rejected on file-level cost. It suits `settings.conf`, whose four fields have no obviously primary one, but triples `dock.conf` from 14 lines to roughly 40 and adds a line to every `reconcile-ignore.conf` record. Supporting both shapes was considered and rejected in turn: it buys a slightly better `settings.conf` at the price of two record shapes for a reader to learn, and one rule beats two.
- **Quoted fields with a quote-aware splitter**: Familiar shape - Rejected as the most machinery and the worst error surface: quotes are legal in filenames so humans must escape quotes inside quotes, newlines still need an escape on top, and it reimplements shell parsing without a shell while `eval` is banned.
- **Forbid newlines and endpoint whitespace, reject at write time** (the `passwd`/systemd pattern): No decoder at all - Partially adopted. Syntactic errors are fatal, but representable-by-encoding was preferred over forbidden for newline and endpoint whitespace, since encoding them costs four cases in an encoder that has to exist for `%` regardless.

### Consequences

**Positive:**
- One parser for all four files; no per-row arity to get wrong.
- Every legal macOS path is representable, and every mis-edit is loud with a line number.
- The common case stays literal and readable, so a Dock change is a one-line diff.
- Machine append is append-only, preserving hand-written comments and ordering above it.

**Negative:**
- `settings.conf` becomes four lines per setting rather than one — more verbose, though each line diffs independently.
- A decoder and encoder must be written and tested, where the positional format needed neither.
- One documented corner remains: a hand-typed value containing `\` followed by `n`, `r`, `t`, `s` or `\` decodes as an escape. Tool-written values are safe, and paths are `stat`ed, so the case surfaces immediately rather than silently.
- `dock.conf` privileges one field per record as the record-start key, so a record whose fields are genuinely co-equal reads slightly awkwardly in `settings.conf`.

---
