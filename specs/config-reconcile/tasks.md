---
references:
    - requirements.md
    - design.md
    - decision_log.md
---
# Implementation Plan: config-reconcile

## Manifest library

- [ ] 1. Write round-trip and rejection tests for the manifest value codec <!-- id:qiiu306 -->
  - New macos/tests/manifest-parse.sh, sourcing macos/lib-manifest.sh via its BASH_SOURCE guard
  - Property: conf_decode(conf_encode(v)) == v for every v composed from the adversarial alphabet (leading space, trailing space, double space, tab, newline, CR, empty, single space, #, =, %, [, quotes, backslash, backslash-then-n, backslash-then-space)
  - Negative half: every \X outside {\\, n, r, t, s} must fail rather than decode
  - Pin the two cases that break naive implementations: a value that is a single space (both endpoint rules fire on one character), and 'x\ ' which must encode to 'x\\\s'
  - Must run under /bin/bash 3.2.57: no declare -A, no mapfile
  - Stream: 1
  - References: design.md#data-models, design.md#property-based-testing

- [ ] 2. Implement conf_encode and conf_decode in macos/lib-manifest.sh <!-- id:qiiu307 -->
  - Escape vocabulary is freedesktop's: \\ \n \r \t \s
  - Escape backslash, newline, CR and tab always; space as \s only at the value's first or last character. Interior spaces stay literal
  - Backslash must be substituted first, or later substitutions double-escape their own output
  - Decoder is pure parameter expansion with a literal-run fast path — no printf %b and no $(...), which strips trailing newlines
  - An unknown \X returns failure so the caller can raise a file:line error
  - Blocked-by: qiiu306 (Write round-trip and rejection tests for the manifest value codec)
  - Stream: 1
  - References: design.md#the-format, decision_log.md#decision-15

- [ ] 3. Write parser tests covering schema enforcement and the six mandatory mechanics <!-- id:qiiu308 -->
  - Extends macos/tests/manifest-parse.sh
  - Schema: unknown key, missing =, attribute before any record, and a missing required attribute must each abort naming file:line
  - Per-file whitelists are scoped — assert 'folder' parses in dock.conf and is rejected in login-items.conf
  - Mechanics with measured failures: callback stdin isolation (a callback reading stdin otherwise consumes the config file), callback exit status ignored (a trailing [ ] test otherwise aborts iteration mid-file), CRLF input (otherwise appends \r to every value), final line with no trailing newline, printf -v newline preservation, record order preservation
  - Also cover comments, blank lines, and ~ expansion to $HOME
  - Blocked-by: qiiu307 (Implement conf_encode and conf_decode in macos/lib-manifest.sh)
  - Stream: 1
  - References: design.md#components-and-interfaces

- [ ] 4. Implement conf_parse, rec_get, rec_require, conf_append_record and backup_path <!-- id:qiiu309 -->
  - Signature: conf_parse FILE RECORD_KEYS ATTR_KEYS CALLBACK; callback sees REC_KIND, REC_VALUE, REC_LINE and the rec_* accessors
  - Split each line on the first =, trim whitespace both sides, strip a trailing CR before parsing
  - conf_append_record appends only, preserving existing content, order and comments (Req 5.5)
  - Copy backup_path from sync-config.sh:31-44 rather than sourcing that file — it sets set -u at line 15, which would leak into verify-setup.sh
  - Trim with parameter expansion, not the skup_trim subshell idiom, which forks per line
  - Blocked-by: qiiu308 (Write parser tests covering schema enforcement and the six mandatory mechanics)
  - Stream: 1
  - Requirements: [5.5](requirements.md#5.5)
  - References: design.md#components-and-interfaces

## Make new-mac.sh sections runnable

- [ ] 5. Write the argv-capture harness and record baseline golden logs <!-- id:qiiu30a -->
  - New macos/tests/refactor-argv.sh, stubbing dockutil, defaults, pmset, systemsetup and killall onto $PATH so each appends its argv to a log
  - Record golden logs in both --local and normal mode before any change, so the refactor is diffed against real current behaviour
  - Data equality against the former array literals is explicitly not the test — it checks the data while the risk lives in the consuming loops, and it self-invalidates the first time adoption appends a dock.conf row
  - Stream: 1
  - References: design.md#the-refactor-test

- [ ] 6. Wrap the Dock, settings and login-item sections in functions behind a BASH_SOURCE guard <!-- id:qiiu30b -->
  - new-mac.sh defines only two functions in 711 lines, so these sections have no entry point and cannot be exercised today
  - Use the same BASH_SOURCE != $0 guard as sync-config.sh:301 and skup:233
  - Structure only — no data moves in this task; the golden logs from the previous task must be byte-identical afterwards in both modes
  - Blocked-by: qiiu30a (Write the argv-capture harness and record baseline golden logs)
  - Stream: 1
  - References: design.md#the-refactor-test

## Extract manifests

- [ ] 7. Extend the argv test with the three deliberate behaviour-change diffs <!-- id:qiiu30c -->
  - Assert each change explicitly rather than letting it pass silently: Dock defaults (new-mac.sh:294-298) and killall Dock move outside the command -v dockutil guard; the Downloads folder becomes a folder row still going to --section others; defaults write failures adopt the uniform warn-and-continue policy
  - Assert the settings loop stays inside the LOCAL guard — outside it, --local would run sudo pmset and system-wide defaults write
  - Assert killall Finder/Dock fire once after the loop, keyed by domain, preserving today's restart count
  - Assert the autorestart fallback chain at new-mac.sh:345-347 is still present in the script and absent from the manifest
  - Blocked-by: qiiu30b (Wrap the Dock, settings and login-item sections in functions behind a BASH_SOURCE guard)
  - Stream: 1
  - Requirements: [8.1](requirements.md#8.1)
  - References: design.md#step-1-is-not-purely-behaviour-preserving

- [ ] 8. Create dock.conf, login-items.conf and settings.conf and convert the consuming loops to read them <!-- id:qiiu30d -->
  - Replaces DOCK_NAMES/DOCK_PATHS (new-mac.sh:239-262), LOGIN_APPS (:421-428), the 12 defaults write lines (:216-228, :294-298) and the pmset/systemsetup setters (:312-342)
  - Record-start keys: dock.conf app/spacer/folder; login-items.conf app; settings.conf defaults/pmset/systemsetup
  - Dropping the parallel DOCK_NAMES/DOCK_PATHS arrays removes the desync failure mode — one record carries a path, with nothing to fall out of step with
  - Generalise the -getremotelogin skip at :329-334 to every systemsetup row rather than losing it as a special case
  - The settings loop runs after the Dock rebuild so the five Dock preferences keep their current relative position
  - Every manifest-driven loop uses process substitution, never a pipe — the right side of a pipe is a subshell and discards increments
  - A syntactically invalid dock.conf is fatal and validated in full before dockutil --remove all, which destroys before it consumes
  - Blocked-by: qiiu309 (Implement conf_parse, rec_get, rec_require, conf_append_record and backup_path), qiiu30c (Extend the argv test with the three deliberate behaviour-change diffs)
  - Stream: 1
  - Requirements: [5.2](requirements.md#5.2)
  - References: design.md#call-site-parity-audit, decision_log.md#decision-6

## Convergence assertions

- [ ] 9. Write tests/verify-exitcode.sh for the exit-code contract <!-- id:qiiu30e -->
  - verify-setup.sh has no exit statement today and always returns 0, leaving specs/skup AC 3.5 unmet
  - Assert non-zero when a convergence assertion fails, and unchanged exit when only drift is present however much is found
  - Assert behaviourally that a failing manifest-driven assertion still produces a non-zero exit — this is what catches a pipeline being used in place of process substitution, which has no other visible symptom
  - Blocked-by: qiiu30d (Create dock.conf, login-items.conf and settings.conf and convert the consuming loops to read them)
  - Stream: 1
  - Requirements: [6.2](requirements.md#6.2)
  - References: design.md#counter-integrity-rules

- [ ] 10. Implement the exit-code contract, the check/note split, per-category counters and argument parsing <!-- id:qiiu30f -->
  - check increments FAIL; note increments a per-category counter and never touches FAIL; the script ends exit $(( FAIL > 0 ))
  - Per-category counts use parallel DRIFT_CATS/DRIFT_NUMS arrays, as skup:29-31 does, since bash 3.2 has no associative arrays
  - Use X=$((X + 1)), never ((X++)) — the latter returns exit status 1 when X is 0, which aborts under set -e
  - verify-setup.sh has no argument parsing at all today; add --adopt (preview) and --adopt --write (apply). Two invocations rather than an interactive prompt, so no TTY is needed to test it
  - Blocked-by: qiiu30e (Write tests/verify-exitcode.sh for the exit-code contract)
  - Stream: 1
  - Requirements: [6.2](requirements.md#6.2), [6.6](requirements.md#6.6)
  - References: design.md#detection-and-reporting, design.md#invocation

- [ ] 11. Write check_setting state and type-comparison tests <!-- id:qiiu30g -->
  - Cover all four states: match, differs, unset, undeterminable
  - unset must be distinct from differs — defaults read on a missing key exits non-zero, which today's check collapses into the same failure as a wrong value (Req 8.5)
  - Type-aware comparison (Req 8.3): bool {true,YES,1} equivalent to 1; int/float numeric; string literal. Without it every boolean reports a permanent difference
  - undeterminable when sudo -n is refused, without blocking for a password (Req 8.4)
  - Blocked-by: qiiu30f (Implement the exit-code contract, the check/note split, per-category counters and argument parsing)
  - Stream: 1
  - Requirements: [8.3](requirements.md#8.3), [8.4](requirements.md#8.4), [8.5](requirements.md#8.5)
  - References: design.md#capturing-changed-system-settings-requirement-8

- [ ] 12. Implement check_setting and drive the Dock, login-item, settings and package assertions from manifests <!-- id:qiiu30h -->
  - check_setting ROW records (row, repo_value, machine_value, state) and reports through check, so the exit-code contract is unchanged
  - Replaces verify-setup.sh's second hardcoded copies: 14 Dock names (:57-61), login-item names (:107-110), the 10 defaults read assertions (:65-77) and the pmset/systemsetup assertions (:78-97)
  - Driving assertions from settings.conf adds two that do not exist today — wvous-br-modifier and AppleHighlightColor are written by new-mac.sh and never checked, so Req 8.1 could never fire for them
  - Replace the fixed 5-package sample (:111-116) with brew bundle check --verbose, measured at 1.04s against roughly 15s for 58 sequential brew list calls (Req 6.3)
  - Blocked-by: qiiu30g (Write check_setting state and type-comparison tests)
  - Stream: 1
  - Requirements: [6.3](requirements.md#6.3), [8.2](requirements.md#8.2), [8.3](requirements.md#8.3), [8.4](requirements.md#8.4), [8.5](requirements.md#8.5)
  - References: design.md#existing-duplication-this-resolves

## Allowlist and drift detection

- [ ] 13. Write tests/drift-allowlist.sh <!-- id:qiiu30i -->
  - Category scoping (Req 4.2): an entry excluding a formula must not exclude an alias of the same name
  - Exact-name matching (Req 4.3)
  - shipped versus owner-added staleness (Req 4.5): only owner-added entries that matched nothing are reported
  - Req 4.6: a machine carrying only Xcode, TestFlight, GarageBand, iMovie, Keynote, Numbers and Pages reports no App Store drift
  - Req 4.7: an absent allowlist file reports all drift without error
  - Blocked-by: qiiu309 (Implement conf_parse, rec_get, rec_require, conf_append_record and backup_path)
  - Stream: 1
  - Requirements: [4.2](requirements.md#4.2), [4.3](requirements.md#4.3), [4.4](requirements.md#4.4), [4.5](requirements.md#4.5), [4.6](requirements.md#4.6), [4.7](requirements.md#4.7)

- [ ] 14. Implement macos/reconcile-ignore.conf and allow_match <!-- id:qiiu30j -->
  - Record-start keys shipped and ignore carry the category; the name attribute carries the free text. Category scoping is structural — an ignore=formula record cannot suppress an alias
  - Ship the seven Apple app entries required by Req 4.6
  - Ship ignore/function/cppr and ignore/export/PRISMPATH: verify-setup.sh:203-205 asserts both are absent from repo shell files, so adopting either would turn three existing assertions red and could then jam adoption through the divergence gate
  - Blocked-by: qiiu30i (Write tests/drift-allowlist.sh)
  - Stream: 1
  - Requirements: [4.1](requirements.md#4.1), [4.2](requirements.md#4.2), [4.3](requirements.md#4.3), [4.4](requirements.md#4.4), [4.5](requirements.md#4.5), [4.6](requirements.md#4.6), [4.7](requirements.md#4.7)
  - References: design.md#macosreconcile-ignoreconf

- [ ] 15. Write tests/drift-packages.sh <!-- id:qiiu30k -->
  - Fixtures are static lists, not live brew output, so the calibration stays meaningful after the machine changes
  - Cover the version-alias case (repo python against installed python@3.13) and the rename case (repo wireshark against installed wireshark-app)
  - Cover the mas id 0 sideloaded entry, which no App Store install can satisfy, as unadoptable
  - Cover brew absent (Req 1.7), mas absent, and mas present-but-signed-out as distinct outcomes (Req 1.6)
  - Blocked-by: qiiu30j (Implement macos/reconcile-ignore.conf and allow_match)
  - Stream: 2
  - Requirements: [1.1](requirements.md#1.1), [1.2](requirements.md#1.2), [1.3](requirements.md#1.3), [1.4](requirements.md#1.4), [1.5](requirements.md#1.5), [1.6](requirements.md#1.6), [1.7](requirements.md#1.7)

- [ ] 16. Implement drift_packages and the three-tier name resolution ladder <!-- id:qiiu30l -->
  - The two directions need different queries: brew leaves and brew list --cask find uncaptured items (hiding transitive deps, Req 1.3), while brew bundle check finds missing ones — brew leaves cannot, because a package installed as a dependency is genuinely absent from it
  - Resolution ladder evaluated lazily so a converged machine never parses the 32MB file: tier 1 formula_aliases.txt (4.8KB grep, ~4ms), tier 2 formula/cask .jws.json plus jq (0.56s, the only tier that resolves renames), tier 3 strip trailing @version
  - Tier 3 cannot satisfy the rename case, so without jq or the cache an unmatched pair is reported as a possible rename rather than asserted — Req 1.4 is met conditionally, not absolutely
  - The .payload field of each .jws.json is a JSON string needing a second parse, which is why tier 2 costs 0.56s
  - Unqualified brew info --json=v2 must not be used — it goes to the network and exceeded 120s; the --installed form runs offline
  - mas list is fixed-width with a right-padded id column; take the first whitespace-delimited field as the id
  - Add cask font-droid-sans-mono-nerd-font to the Brewfile so Req 1.2 holds. gh is already at Brewfile:11 and its direct install at new-mac.sh:55 must stay — it runs before gh auth login at :87, while brew bundle is at :186
  - Blocked-by: qiiu30k (Write tests/drift-packages.sh)
  - Stream: 2
  - Requirements: [1.1](requirements.md#1.1), [1.2](requirements.md#1.2), [1.3](requirements.md#1.3), [1.4](requirements.md#1.4), [1.5](requirements.md#1.5), [1.6](requirements.md#1.6), [1.7](requirements.md#1.7)
  - References: design.md#package-name-resolution-req-14, decision_log.md#decision-2

- [ ] 17. Write tests/drift-shell.sh for function, alias and environment drift <!-- id:qiiu30m -->
  - Fixture $HOME exercising the classification order: empty provenance, repo-linked file reached via symlink, $ZSH_CUSTOM/plugins, $ZSH_CUSTOM itself, ~/.oh-my-zsh, and a file reached via an already-reported source line
  - Assert an empty functions_source is excluded — 989 of 1126 functions on the calibration machine are autoload stubs, so without this the first run reports ~989 findings
  - Assert $ZSH_CUSTOM is classified before ~/.oh-my-zsh: it sits inside the oh-my-zsh tree but holds the user's own config, and ~/.zshrc:98 tells the user to put aliases there
  - Conflicts: a name machine-local by provenance that also appears in macos/aliases.zsh (Reqs 2.4, 2.5)
  - Req 7.2: the ~/.local/bin PATH addition must not be reported — it comes from the managed-block heredoc in sync-config.sh:281-285, not from zshrc.snippet, so checking only the snippet reports it as drift every run
  - Req 7.5: a conditional block is one item named by its opening line
  - Blocked-by: qiiu30j (Implement macos/reconcile-ignore.conf and allow_match)
  - Stream: 2
  - Requirements: [2.1](requirements.md#2.1), [2.2](requirements.md#2.2), [2.3](requirements.md#2.3), [2.4](requirements.md#2.4), [2.5](requirements.md#2.5), [2.6](requirements.md#2.6), [7.1](requirements.md#7.1), [7.2](requirements.md#7.2), [7.4](requirements.md#7.4), [7.5](requirements.md#7.5)

- [ ] 18. Implement drift_shell function provenance, alias scanning and conflict detection <!-- id:qiiu30n -->
  - Functions use zsh runtime provenance: one zsh -ic invocation loading zsh/parameter, emitting name<TAB>$functions_source[name]
  - That stdout is not clean — the random oh-my-zsh theme prints a banner that differs every run and iTerm2 injects escape sequences, so delimit the payload with a sentinel line and discard everything outside it
  - Rule 2 must resolve symlinks: ~/.aliases.zsh is a symlink to macos/aliases.zsh, and comparing literal paths would misclassify every repo function as machine-local
  - zsh exposes no provenance equivalent for aliases, so scan them textually across ~/.zshrc, ~/.zshenv, ~/.zprofile, ~/.zlogin and $ZSH_CUSTOM/*.zsh. This misses conditionally-defined aliases — accepted, and the reason Req 2.5 claims no winner
  - Conflicts need a second pass: functions_source returns only the effective definition, so intersect provenance with a textual scan of the repo-managed file
  - Blocked-by: qiiu30m (Write tests/drift-shell.sh for function, alias and environment drift)
  - Stream: 2
  - Requirements: [2.1](requirements.md#2.1), [2.2](requirements.md#2.2), [2.3](requirements.md#2.3), [2.4](requirements.md#2.4), [2.5](requirements.md#2.5), [2.6](requirements.md#2.6)
  - References: design.md#shell-drift-reqs-2-7, decision_log.md#decision-8

- [ ] 19. Implement drift_env for exports, PATH additions, source lines and conditional blocks <!-- id:qiiu30o -->
  - Scan the same Req 2.6 file set as the alias scan
  - Exclusion source is two places, not one: macos/zshrc.snippet and the managed-block heredoc inside sync-config.sh:281-285
  - Track block depth so a conditional block is emitted as one item — this is why the scanner is line-oriented rather than a grep
  - Report a value that cannot be expressed independently of this machine as unadoptable with its reason (Req 7.4)
  - Blocked-by: qiiu30m (Write tests/drift-shell.sh for function, alias and environment drift), qiiu30n (Implement drift_shell function provenance, alias scanning and conflict detection)
  - Stream: 2
  - Requirements: [7.1](requirements.md#7.1), [7.2](requirements.md#7.2), [7.4](requirements.md#7.4), [7.5](requirements.md#7.5)
  - References: design.md#shell-drift-reqs-2-7

- [ ] 20. Write tests/drift-dock.sh <!-- id:qiiu30p -->
  - Percent-decoding of dockutil URLs, spacer rows (empty name and empty URL), and the two independent sections
  - Order compared over the intersection, not positionally: the calibration machine has 21 persistentApps against 16 manifest rows, and a positional diff would report every position after the first uncaptured item as an order difference
  - Paths compare as bytes with no Unicode normalisation — APFS does not normalise to NFD, so folding both sides would invent differences between a Dock and a manifest that agree
  - Login-item query bounded and non-blocking (Req 3.5)
  - Blocked-by: qiiu30d (Create dock.conf, login-items.conf and settings.conf and convert the consuming loops to read them), qiiu30j (Implement macos/reconcile-ignore.conf and allow_match)
  - Stream: 1
  - Requirements: [3.1](requirements.md#3.1), [3.2](requirements.md#3.2), [3.3](requirements.md#3.3), [3.4](requirements.md#3.4), [3.5](requirements.md#3.5), [3.6](requirements.md#3.6)

- [ ] 21. Implement drift_dock, drift_login_items and the bounded login-item query <!-- id:qiiu30q -->
  - dockutil --list emits tab-separated name, file:// URL, section, plist, bundle-id; map persistentApps/persistentOthers to the apps/others that --add takes
  - timeout cannot be used — neither timeout nor gtimeout is on a stock macOS install, and AppleScript's own with timeout does not help because what blocks is a TCC consent dialog, not a slow Apple event
  - Run osascript in the background writing to a temp file, poll in short sleeps to a fixed ceiling, then kill and report the category undeterminable, naming the Automation permission to grant
  - Blocked-by: qiiu30p (Write tests/drift-dock.sh)
  - Stream: 1
  - Requirements: [3.1](requirements.md#3.1), [3.2](requirements.md#3.2), [3.3](requirements.md#3.3), [3.4](requirements.md#3.4), [3.5](requirements.md#3.5), [3.6](requirements.md#3.6)
  - References: design.md#dock-comparison-reqs-32-34, design.md#bounding-the-login-item-query-req-35

## Adoption

- [ ] 22. Write tests/adopt.sh <!-- id:qiiu30r -->
  - Preview writes nothing (Reqs 5.3, 5.4); a second run with no new drift changes no file (Req 5.6)
  - All-or-nothing: a failing write leaves every touched file as it was found (Req 5.9)
  - Per-category gate refusals, each naming the blocking condition (Req 5.7)
  - Assert absence and undeterminable do NOT block — a FAIL == 0 gate would deadlock on day one, since brew bundle check already reports seven absent casks and sudo -n systemsetup -getremotelogin already fails at verify-setup.sh:90-91
  - Req 7.3: a value rooted at this user's home is written as ~ into a manifest and as a literal $HOME into aliases.zsh; a home path appearing mid-value is not rewritten but reported unadoptable
  - Assert nothing is staged, committed or pushed (Req 5.11)
  - Blocked-by: qiiu30l (Implement drift_packages and the three-tier name resolution ladder), qiiu30o (Implement drift_env for exports, PATH additions, source lines and conditional blocks), qiiu30q (Implement drift_dock, drift_login_items and the bounded login-item query)
  - Stream: 1
  - Requirements: [5.3](requirements.md#5.3), [5.4](requirements.md#5.4), [5.5](requirements.md#5.5), [5.6](requirements.md#5.6), [5.7](requirements.md#5.7), [5.8](requirements.md#5.8), [5.9](requirements.md#5.9), [5.10](requirements.md#5.10), [5.11](requirements.md#5.11), [7.3](requirements.md#7.3)

- [ ] 23. Implement adopt_plan and adopt_preview <!-- id:qiiu30s -->
  - adopt_plan produces (file, verb, row, source_item) writes and is pure; preview and apply both consume it so they cannot disagree about what would be written
  - Targets: packages to Brewfile, Dock to dock.conf, login items to login-items.conf, settings to settings.conf, and aliases/functions/exports/source lines to macos/aliases.zsh. new-mac.sh is never written (Req 5.2)
  - aliases.zsh is the target precisely because multi-line items exist — md2pdf and lorb are multi-line functions with comments, and no single-line row shape holds them
  - Rewrite a leading home prefix before writing (Req 7.3): ~ for manifests, which conf_parse expands at read time, and a literal $HOME for aliases.zsh, which the shell sources. Prefix matches only — a mid-value occurrence cannot be known to be a path root, so the item is reported unadoptable instead
  - Idempotency falls out of the plan being a set difference against current manifest contents (Req 5.6)
  - Items reported unadoptable are named and skipped while the rest still adopt (Req 5.8); a check_setting row in state differs offers its machine value (Req 8.1)
  - Blocked-by: qiiu30r (Write tests/adopt.sh)
  - Stream: 1
  - Requirements: [5.1](requirements.md#5.1), [5.2](requirements.md#5.2), [5.3](requirements.md#5.3), [5.4](requirements.md#5.4), [5.8](requirements.md#5.8), [7.3](requirements.md#7.3), [8.1](requirements.md#8.1)

- [ ] 24. Implement adopt_gate and write the applied-marker from new-mac.sh <!-- id:qiiu30t -->
  - Three conditions, each named when it blocks: a repo-managed item in that category differs on the machine (per category), target files dirty (git diff --quiet on the target files; an untracked new manifest does not block), and settings never applied on this machine (global)
  - The divergence gate is per category because only settings and shell conflicts have a differs state — Dock, login items and packages are membership-only, so a global gate would import the settings category's problems into them
  - new-mac.sh must write ~/.workscripts-applied on completing the non---local settings block. No marker exists today, and LOCAL is only an in-memory variable, so the gate's most important condition is otherwise unimplementable
  - Without it, adopting on a machine that never had settings applied overwrites the repo's intended Dock with whatever macOS defaulted to
  - Blocked-by: qiiu30s (Implement adopt_plan and adopt_preview)
  - Stream: 1
  - Requirements: [5.7](requirements.md#5.7)
  - References: design.md#adoption-flow

- [ ] 25. Implement adopt_apply with all-or-nothing writes and backups <!-- id:qiiu30u -->
  - Write each target to a sibling temporary path and move them into place only when every write succeeds (Req 5.9)
  - Back up using the backup_path helper copied into lib-manifest.sh
  - Append only, preserving existing content, order and comments (Req 5.5)
  - Return the list of files and entries written so adopt_preview renders it identically (Req 5.10)
  - Never stage, commit or push (Req 5.11)
  - Blocked-by: qiiu30t (Implement adopt_gate and write the applied-marker from new-mac.sh)
  - Stream: 1
  - Requirements: [5.5](requirements.md#5.5), [5.9](requirements.md#5.9), [5.10](requirements.md#5.10), [5.11](requirements.md#5.11)

## Reporting and documentation

- [ ] 26. Implement the drift report rendering and wire it into the verification run <!-- id:qiiu30v -->
  - Presentation only — counts come from the already-tested per-category counters, and per Decision 9 no test parses rendered output
  - Drift renders as an indented list under a per-category heading prefixed ~, with no checkmark or cross anywhere in the block, so it is distinguishable at a glance and by grep
  - Print each category's count and an explicit none line when empty (Reqs 6.5, 6.6)
  - Head the block with a statement that drift does not affect the result, so thirty items are not read as thirty failures
  - unadoptable items count toward their category total — they are genuine drift, and excluding them would make the count disagree with the visible list
  - Confirm the added wall-clock stays within the 2s budget (Req 6.7); the measured common path is about 0.50s
  - Blocked-by: qiiu30l (Implement drift_packages and the three-tier name resolution ladder), qiiu30o (Implement drift_env for exports, PATH additions, source lines and conditional blocks), qiiu30q (Implement drift_dock, drift_login_items and the bounded login-item query)
  - Stream: 1
  - Requirements: [6.1](requirements.md#6.1), [6.4](requirements.md#6.4), [6.5](requirements.md#6.5), [6.6](requirements.md#6.6), [6.7](requirements.md#6.7)
  - References: design.md#report-rendering-req-64

- [ ] 27. Update the guide and agent notes to point at the manifests <!-- id:qiiu30w -->
  - docs/new-mac-guide.md:248-249 documents DOCK_NAMES/DOCK_PATHS and LOGIN_APPS as the customisation points and must point at dock.conf, login-items.conf and settings.conf instead
  - Record in docs/agent-notes/ the manifest format, the counter-integrity rules, and the six parser mechanics, since each has a measured failure that is invisible in review
  - specs/mac-env-setup/* and CHANGELOG.md describe past state and are not updated
  - Blocked-by: qiiu30u (Implement adopt_apply with all-or-nothing writes and backups), qiiu30v (Implement the drift report rendering and wire it into the verification run)
  - Stream: 1
