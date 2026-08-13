# Requirements: config-reconcile

## Introduction

The workscripts macOS setup only syncs in one direction: `sync-config.sh` pushes repo-managed config onto the machine and `verify-setup.sh` asserts the machine matches. Nothing reports the reverse — software installed and settings changed on the Mac that the repo never captured — so the repo quietly stops being the single source of truth. This feature adds that reverse direction: a report of machine state the repo does not yet own, and an opt-in mode that writes it back into repo-managed data for review.

## Out of Scope

- Linux and Windows/PowerShell — macOS only; the `powershell/` and `windows/` trees are untouched.
- Background or scheduled drift checks — the report runs when `verify-setup.sh` is invoked; no daemon, agent, or cron entry.
- Committing or pushing to git — adoption leaves an uncommitted working-tree change for review.
- Removing anything from the machine — the feature never uninstalls a package or deletes a setting to force convergence.
- Removing entries from repo files — adoption only adds; pruning stays manual.
- The repo→machine direction — reporting repo-managed items the machine lacks is already the job of the convergence assertions in `verify-setup.sh`, and stays there ([6.2](#6.2)).
- Software installed outside Homebrew and the App Store — VS Code extensions, and globals installed via `pnpm`, `uv`, `nvm` or `go install`.
- Version pinning — a package is captured by name; matching installed versions against repo-managed data is not attempted.
- A machine-readable output mode — the report is for a human reading a terminal; nothing consumes it programmatically.

## Requirements

### 1. Package drift detection

**User Story:** As the machine owner, I want to see which Homebrew and App Store software is installed but not captured by the repo, so that a rebuilt Mac gets the tools I actually use.

**Acceptance Criteria:**

1. <a name="1.1"></a>The system SHALL report Homebrew formulae, Homebrew casks, and Mac App Store applications installed on the machine that the repo does not install, grouped by kind.  
2. <a name="1.2"></a>The set of packages the repo installs SHALL include every package named anywhere in the repo's setup, not only those in the package manifest. Given the current repo, `gh` and `font-droid-sans-mono-nerd-font` are installed by setup outside the manifest and SHALL NOT be reported as uncaptured.  
3. <a name="1.3"></a>WHEN a formula is installed only because another formula depends on it, it SHALL NOT be reported as uncaptured. Given the current machine, `sqlite` and comparable transitive dependencies SHALL NOT appear.  
4. <a name="1.4"></a>The system SHALL resolve an installed package and a repo-named package to the same identity when they differ only by version suffix or by an upstream rename, and SHALL NOT report either as uncaptured. Given the current machine, repo `python` against installed `python@3.13`, and repo `wireshark` against installed `wireshark-app`, SHALL each resolve to one identity.  
5. <a name="1.5"></a>WHEN an installed item cannot be expressed in a form that setup could reinstall, the system SHALL report it as unadoptable and state why. Given the current machine, the sideloaded App Store entry `prism` carries id `0`, which no App Store install can satisfy.  
6. <a name="1.6"></a>IF the Mac App Store query tool is not installed, THEN the system SHALL report that App Store drift is undeterminable and name the tool needed; IF the tool is present but not signed in, THEN the system SHALL report that distinctly. Homebrew drift SHALL still be reported in both cases.  
7. <a name="1.7"></a>IF Homebrew is not installed, THEN the system SHALL report package drift as undeterminable and SHALL still report the remaining drift categories.  

### 2. Shell configuration drift detection

**User Story:** As the machine owner, I want aliases and functions I added directly to my shell config reported, so that they stop being lost on a rebuild.

**Acceptance Criteria:**

1. <a name="2.1"></a>The system SHALL report shell functions whose definition came from a machine-local file rather than from a repo-managed file, listing each by name and originating file. Given the current machine, `cppr` originates from `~/.zshrc` and SHALL be reported, while `lorb` and `md2pdf` originate from the repo-linked aliases file and SHALL NOT.  
2. <a name="2.2"></a>The system SHALL report aliases defined in machine-local shell config that are absent from the repo-managed aliases file, listing each by name.  
3. <a name="2.3"></a>The system SHALL NOT report aliases or functions originating from oh-my-zsh, its plugins, or its completion machinery.  
4. <a name="2.4"></a>WHEN a function name is defined both in machine-local config and in repo-managed config, the system SHALL report it as a conflict, name the file whose definition is in effect, and show both bodies.  
5. <a name="2.5"></a>WHEN an alias name is defined both in machine-local config and in repo-managed config, the system SHALL report it as a conflict and show both bodies, without asserting which one is in effect.  
6. <a name="2.6"></a>The system SHALL enumerate machine-local shell config as a stated set of files, including the oh-my-zsh custom directory that `~/.zshrc` itself recommends for user aliases.  

### 3. macOS settings drift detection

**User Story:** As the machine owner, I want login items and Dock entries present on my Mac but not in the repo reported, so that a rebuilt Mac reproduces the desktop I actually use.

**Acceptance Criteria:**

1. <a name="3.1"></a>The system SHALL report login items present on the machine that are absent from the repo-managed login item list.  
2. <a name="3.2"></a>The system SHALL report Dock entries present on the machine that are absent from the repo-managed Dock list.  
3. <a name="3.3"></a>WHEN the machine's Dock and the repo-managed Dock list contain the same entries in a different order, the system SHALL report the order difference, because the repo-managed list determines the order a rebuilt Dock is created in.  
4. <a name="3.4"></a>The system SHALL treat Dock separators and percent-encoded application paths as equivalent to their repo-managed forms, so that neither is reported as drift when it matches.  
5. <a name="3.5"></a>IF the login item query requires an automation permission that has not been granted, THEN the system SHALL report the category as undeterminable and name the permission, and SHALL NOT block waiting for it. The system SHALL bound this wait using only tools present on a stock macOS install.  
6. <a name="3.6"></a>IF a query tool required for a settings category is unavailable, THEN that category SHALL be reported as undeterminable and the remaining categories SHALL still be reported.  

### 4. Machine-local allowlist

**User Story:** As the machine owner, I want to mark config as deliberately machine-specific, so that the same items stop being reported on every run.

**Acceptance Criteria:**

1. <a name="4.1"></a>The system SHALL read a repo-managed allowlist naming items never reported as drift, covering every category in requirements [1](#1.1), [2](#2.1) and [3](#3.1).  
2. <a name="4.2"></a>An allowlist entry SHALL apply to exactly one named drift category, so that an entry excluding a formula does not also exclude an alias of the same name.  
3. <a name="4.3"></a>An allowlist entry SHALL match an item by its exact name.  
4. <a name="4.4"></a>WHEN an item matches the allowlist, it SHALL be excluded from the drift report and SHALL NOT be written to any repo file by adoption ([5.1](#5.1)).  
5. <a name="4.5"></a>The allowlist SHALL distinguish entries shipped with the repo from entries the machine owner added, and SHALL report only owner-added entries that matched nothing, so that a stale personal exclusion is visible while a shipped default for software this Mac lacks stays quiet.  
6. <a name="4.6"></a>The allowlist SHALL ship with entries for software macOS supplies or the App Store reinstalls automatically, such that a machine carrying only Xcode, TestFlight, GarageBand, iMovie, Keynote, Numbers and Pages reports no App Store drift.  
7. <a name="4.7"></a>IF the allowlist file is absent, THEN the system SHALL report all drift without error.  

### 5. Adoption into the repo

**User Story:** As the machine owner, I want a command that writes uncaptured items into the repo, so that capturing drift is not manual transcription.

**Acceptance Criteria:**

1. <a name="5.1"></a>WHEN adoption is confirmed, the system SHALL write every uncaptured item from requirements [1](#1.1), [2](#2.1) and [3](#3.1) into the repo file that owns it, such that a subsequent setup run installs or applies that item.  
2. <a name="5.2"></a>Adoption SHALL NOT write to any file containing control flow, so that no write can alter program logic or produce a script that behaves differently from the one reviewed. Appending a self-contained definition to a file that holds only definitions is permitted; modifying a file that holds loops, conditionals or commands is not.  
3. <a name="5.3"></a>By default the system SHALL only preview: it SHALL name every file it would change and every entry it would add, and change nothing. Writing SHALL require a separate explicit confirmation.  
4. <a name="5.4"></a>WHEN adoption is not confirmed, the system SHALL NOT modify any file in the repository or any repo-managed file in the home directory.  
5. <a name="5.5"></a>The system SHALL preserve each written file's existing content, entry order and comments, adding only new entries.  
6. <a name="5.6"></a>WHEN adoption runs a second time with no new drift, it SHALL make no change to any repo file.  
7. <a name="5.7"></a>The system SHALL refuse to adopt a category when a repo-managed item in that category is present on the machine with a differing value, and SHALL refuse all adoption when the repo files it would write have uncommitted changes or when the machine has never had repo settings applied. It SHALL state which condition blocked it. A repo-managed item merely absent from the machine, or undeterminable, SHALL NOT block adoption — absence is not evidence about whether machine state is intended.  
8. <a name="5.8"></a>WHEN adoption cannot represent an item ([1.5](#1.5)), it SHALL skip that item, name it, and still adopt the rest.  
9. <a name="5.9"></a>WHEN adoption writes to more than one file and any write fails, the system SHALL leave every file it touched as it found them and report the failure.  
10. <a name="5.10"></a>WHEN adoption changes a file, the system SHALL name each file changed and each entry added.  
11. <a name="5.11"></a>The system SHALL NOT stage, commit or push any change it makes.  

### 6. Reporting and integration

**User Story:** As the machine owner, I want drift shown whenever I check my setup, so that I do not have to remember a separate command.

**Acceptance Criteria:**

1. <a name="6.1"></a>The existing verification run SHALL end with a drift report covering every category in requirements [1](#1.1), [2](#2.1) and [3](#3.1).  
2. <a name="6.2"></a>The verification run SHALL exit non-zero when any convergence assertion fails, satisfying the existing unmet requirement in `specs/skup` AC 3.5; drift, however much is found, SHALL NOT affect the exit code.  
3. <a name="6.3"></a>The verification run's package convergence assertion SHALL check every package the repo installs rather than a fixed sample of five.  
4. <a name="6.4"></a>The drift report SHALL be visually distinct from convergence assertion results, so that uncaptured drift is not read as a failed assertion.  
5. <a name="6.5"></a>WHEN no drift is found in a category, the report SHALL say so explicitly rather than omitting the category.  
6. <a name="6.6"></a>The drift report SHALL state a total count per category.  
7. <a name="6.7"></a>Once every permission the report needs has been granted, adding the drift report SHALL increase the verification run's wall-clock time by no more than 2 seconds.  

### 7. Environment and shell integration drift

**User Story:** As the machine owner, I want environment variables, PATH additions and shell integrations I added locally reported, so that a rebuilt Mac does not lose them.

**Acceptance Criteria:**

1. <a name="7.1"></a>The system SHALL report environment variable assignments, `PATH` additions and `source` lines present in machine-local shell config that the repo does not set. Given the current machine, the `PATH` additions for LM Studio, `rune`, `orbit` and BaseRT, the `LESS` assignment, and the iTerm2 shell-integration `source` line SHALL be reported.  
2. <a name="7.2"></a>The system SHALL NOT report an assignment the repo already makes by another route. Given the current machine, the `~/.local/bin` `PATH` addition is already made by the repo-managed block in `~/.zshrc` and SHALL NOT be reported.  
3. <a name="7.3"></a>WHEN an item's value contains a path under the current user's home directory, adoption SHALL write it in a form that resolves to the equivalent path on another machine, satisfying the existing constraint in `specs/skup` AC 4.1 that machine-specific paths are not hard-coded into repo files.  
4. <a name="7.4"></a>WHEN an item's value contains a path that cannot be expressed independently of this machine, the system SHALL report it as unadoptable and state why, per [1.5](#1.5). Given the current machine, `PRISMPATH` points into a user-specific iCloud container.  
5. <a name="7.5"></a>The system SHALL report a conditional block in machine-local shell config as a single named item rather than as its individual lines, so that a block such as the SSH keychain unlock is adopted or skipped whole.  

### 8. Capturing changed system settings

**User Story:** As the machine owner, I want a setting I deliberately changed on this Mac to be capturable into the repo, so that the repo records my current intent rather than a stale value.

**Acceptance Criteria:**

1. <a name="8.1"></a>WHEN a convergence assertion reports that a repo-managed `defaults`, `pmset` or `systemsetup` setting differs on this machine, the system SHALL offer that setting's current machine value for adoption into repo-managed data.  
2. <a name="8.2"></a>The system SHALL NOT report these settings as a separate drift category, because the existing convergence assertions already report the difference ([6.2](#6.2)); adoption acts on what those assertions found.  
3. <a name="8.3"></a>The system SHALL compare a machine value against the repo-managed value using the setting's type, so that a value written as `-bool true` and read back as `1` is not reported as a difference.  
4. <a name="8.4"></a>IF reading a setting requires elevated privileges that are not available without prompting, THEN the system SHALL report that setting as undeterminable and SHALL NOT block waiting for a password. Given the current setup, the remote-login state is read this way.  
5. <a name="8.5"></a>WHEN a repo-managed setting has never been set on this machine, it SHALL be reported as unset rather than as a differing value.  
