# Requirements: skup

## Introduction

The Mac setup currently copies and appends shell config from GitHub raw URLs, so local machines drift from the repo and `new-mac.sh` cannot safely re-run. This feature makes the cloned workscripts repo the single source of truth: repo-managed config is linked into place (the way `agentic-coding` links into `~/.claude`), brew packages move to an editable manifest, and `new-mac.sh` becomes an idempotent script that converges any Mac — fresh or badly configured — to the same end state. It also adds `skup`, a command that opens a tagged set of work environments (tmux sessions with dev servers) in one step.

## Out of Scope

- Windows/PowerShell profile linking — macOS only; the `powershell/` tree is untouched.
- Changes to the project repos themselves (sdd-ui, rtob, toes, siteme, brandme, sanarte, finance) — skup starts each repo's existing dev-server entry point, it does not add or modify them.
- Wholesale management of `~/.zshrc` — oh-my-zsh keeps ownership; the repo contributes a sourced snippet only, and the oh-my-zsh install line stays machine-local.
- Removing the curl-based bootstrap path — `new-mac.sh` must still be runnable on a machine with nothing installed, so existing `macos/` raw-URL paths stay where they are.
- Background/automatic syncing — updates arrive by `git pull` in the repo; no daemon or scheduled job.
- Per-repo tmux layouts beyond a server window and a shell window.
- Server health monitoring beyond a one-shot liveness check at `skup` invocation — no ongoing supervision, restart-on-crash-while-detached, or log aggregation.
- Linux support.

## Requirements

### 1. Linked shell configuration

**User Story:** As the machine owner, I want repo-managed shell config linked into my home directory rather than copied, so that a `git pull` in workscripts updates every machine without re-running setup.

**Acceptance Criteria:**

1. <a name="1.1"></a>The system SHALL link an enumerated set of repo-managed config files into the home directory — at minimum the aliases file, the vimrc, and a repo-managed zsh snippet (see [4.3](#4.3)) — such that editing the repo file and re-opening a shell reflects the change without re-copying. The enumerated set SHALL be the complete list of files the sync operation manages; nothing outside it is linked.  
2. <a name="1.2"></a>WHEN `~/.zshrc` does not yet source the repo-managed zsh snippet, the sync operation SHALL add a single guarded source line for it to `~/.zshrc`; re-running SHALL never add a second such line.  
3. <a name="1.3"></a>WHEN a link target already exists as a regular file (the expected case on an already-configured Mac, where `~/.vimrc` and `~/.aliases.zsh` are downloaded copies), the sync operation SHALL preserve the existing file at a write-once, collision-safe backup path before replacing it with the link, and SHALL report what it did. A subsequent re-run (target already the correct link) SHALL make no backup and no change.  
4. <a name="1.4"></a>The sync operation SHALL be runnable on its own (without the full `new-mac.sh`), SHALL require no `sudo`, and SHALL exit non-zero with a plain-language message if the repo layout it expects is missing.  

### 2. Package manifest

**User Story:** As the machine owner, I want brew packages defined in a manifest file, so that changing what gets installed means editing data, not script code.

**Acceptance Criteria:**

1. <a name="2.1"></a>The system SHALL define all Homebrew formulae, casks, and Mac App Store apps in a repo-managed manifest file, and `new-mac.sh` SHALL install from that manifest rather than from arrays embedded in the script  
2. <a name="2.2"></a>WHEN a package in the manifest fails to install, the remaining packages SHALL still be attempted and the failures SHALL be listed in the run summary (preserving current behaviour)  
3. <a name="2.3"></a>WHEN the manifest is edited and `new-mac.sh` (or the install step alone) is re-run, packages already installed SHALL be skipped without error and new entries SHALL be installed  
4. <a name="2.4"></a>WHEN the App Store is not signed in, Mac App Store entries SHALL be skipped with a clear warning naming them, and the rest of the manifest SHALL still install (so a run with no Apple ID does not fail)  

### 3. Idempotent convergence of new-mac.sh

**User Story:** As the machine owner, I want `new-mac.sh` to be safely re-runnable on any Mac, so that the same script bootstraps a new machine, uplifts a badly configured one, and can be tested on my current machine.

**Acceptance Criteria:**

1. <a name="3.1"></a>WHEN `new-mac.sh` is re-run on an already-configured Mac, it SHALL complete without error and without duplicating any configuration (no repeated `~/.zshrc` source lines or blocks, login items, Dock entries, or git config)  
2. <a name="3.2"></a>The migrated `~/.zshrc` content the setup writes SHALL be enclosed in explicit begin/end markers so that a re-run replaces the marked region in place rather than appending a second copy, and content the user added outside the markers SHALL be left untouched  
3. <a name="3.3"></a>WHEN `new-mac.sh` runs on a machine carrying the old curl-appended `~/.zshrc` content (which has a start marker but no end marker, followed by further unmarked appends), it SHALL migrate that content to the marked, linked model so that exactly one source of each setting remains, and the previous `~/.zshrc` SHALL be preserved at a write-once, collision-safe backup path (not overwriting an earlier backup, and not colliding with the existing `removetheme` alias's `~/.zshrc.bak`)  
4. <a name="3.4"></a>The system SHALL provide a local mode that runs only the no-sudo steps (linking, snippet sourcing, manifest install, skup config) with no side effects beyond the user's home directory, skipping the interactive SSH/`gh auth` and sudo-requiring system steps, so the current Mac can serve as the test bed  
5. <a name="3.5"></a>The system SHALL provide a verify step (extending the existing `macos/verify-setup.sh`) that asserts the converged end state — expected links present and pointing at the repo, no duplicated `~/.zshrc` markers, and a valid skup config — and exits non-zero listing any failed assertion  
6. <a name="3.6"></a>WHEN any individual section fails, `new-mac.sh` SHALL continue with the remaining sections and report the failures in the summary (preserving current behaviour)  
7. <a name="3.7"></a>Running `new-mac.sh` on a fresh machine and running it on a drifted machine SHALL converge on the same observable end state as asserted by the verify step ([3.5](#3.5))  

### 4. Drift capture

**User Story:** As the machine owner, I want the shell config I actually use (currently only in my local `~/.zshrc`) captured into the repo, so that the linked files are genuinely the single source of truth.

**Acceptance Criteria:**

1. <a name="4.1"></a>The repo-managed shell config SHALL include the local-only aliases and functions currently in daily use on the existing Mac (including the `t` tmux helper), verified against the live `~/.zshrc`, and they SHALL resolve identically in a new shell after migration. Machine-specific paths in captured config SHALL NOT be hard-coded into the repo files.  
2. <a name="4.2"></a>WHEN migration completes on the existing Mac, `~/.zshrc` SHALL contain only the oh-my-zsh install line, machine-specific settings, and the guarded source line(s) for the repo snippet — no repo-duplicated content  
3. <a name="4.3"></a>The repo SHALL provide a zsh snippet holding the sourceable oh-my-zsh settings (theme selection, plugin list, history and shell options, aliases) that is safe to `source` from `~/.zshrc` without re-running the oh-my-zsh installer; the oh-my-zsh bootstrap (`source $ZSH/oh-my-zsh.sh`) SHALL remain in the machine-local `~/.zshrc`  

### 5. skup command

**User Story:** As the machine owner, I want a single command `skup [tag]` that opens the set of repos/work environments for that tag, so that starting a day's work on any context is one step from any shell.

**Acceptance Criteria:**

1. <a name="5.1"></a>The `skup` command SHALL be invocable from any interactive shell after setup, placed on `PATH` at a stated location by the sync operation  
2. <a name="5.2"></a>Tags and their repo sets SHALL be defined in a repo-managed config file; any ad hoc tag name (e.g. feature, meta, project, billing, client, contract) SHALL work once defined there  
3. <a name="5.3"></a>The start command for each repo SHALL be determined by detection — `make dev` when the repo's Makefile defines a `dev` target, else `pnpm dev` when `package.json` defines that script, else none — and the tag config MAY override the command per repo  
4. <a name="5.4"></a>WHEN `skup <tag>` is invoked for a defined tag, THEN for each repo in the tag's set the system SHALL ensure a tmux session named after the repo exists, with the repo's detected/overridden start command ([5.3](#5.3)) running in one window and a free shell in another, processing repos in the order they appear in the config and attaching to the first repo's session  
5. <a name="5.5"></a>WHEN a repo has no start command (none detected and none configured, e.g. a specs-only repo), its session SHALL open with the shell window only  
6. <a name="5.6"></a>WHEN `skup` is invoked with no tag, it SHALL open the config-designated default set  
7. <a name="5.7"></a>WHEN `skup <tag>` names a tag not present in the config, it SHALL exit non-zero and list the known tags  
8. <a name="5.8"></a>WHEN a session for a repo already exists, `skup` SHALL reuse it rather than creating a duplicate; and WHEN that repo has a start command whose process is not currently running in its window, `skup` SHALL re-issue the start command before attaching, so the end state is servers running for every repo with a start command  
9. <a name="5.9"></a>WHEN invoked from inside an existing tmux session, `skup` SHALL switch to the target session rather than nesting tmux  
10. <a name="5.10"></a>WHEN a repo named in the config is missing from disk, `skup` SHALL say so, skip it, and continue with the remaining repos  

### 6. Bootstrap compatibility

**User Story:** As the machine owner, I want the one-line curl bootstrap to keep working, so that a brand-new Mac with nothing installed can still start from `new-mac.sh` alone.

**Acceptance Criteria:**

1. <a name="6.1"></a>`new-mac.sh` SHALL remain runnable via curl before the repo exists locally, and SHALL reach the linked-configuration end state by cloning the repo and invoking the sync operation from the clone  
2. <a name="6.2"></a>Existing raw-URL paths under `macos/` that the bootstrap depends on SHALL remain valid (files may be added, not moved or renamed)  
