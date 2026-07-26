---
references:
    - requirements.md
    - design.md
    - decision_log.md
---
# skup Implementation Tasks

## Config linking

- [x] 1. Split macos/zshrc into a sourceable zshrc.snippet <!-- id:pp5y8f4 -->
  - Create macos/zshrc.snippet with only installer-free settings: ZSH_THEME, ZSH_THEME_RANDOM_CANDIDATES, HYPHEN_INSENSITIVE, DISABLE_UNTRACKED_FILES_DIRTY, setopt shwordsplit, setopt EXTENDED_HISTORY, LSCOLORS, plugins=(brew vim-interaction zsh-interactive-cd zsh-navigation-tools)
  - Must NOT include export ZSH, the source $ZSH/oh-my-zsh.sh bootstrap, or any oh-my-zsh install line — those stay machine-local
  - Refactor/config task, no preceding test
  - Stream: 1
  - Requirements: [4.3](requirements.md#4.3)

- [x] 2. Write tests for link_file and backup_path <!-- id:pp5y8f5 -->
  - macos/tests/sync-config-link.sh: a correct existing symlink is a no-op and creates no backup; an existing regular file is backed up then replaced by the link; a same-second second backup gets a numeric counter suffix (write-once); backups live under ~/.workscripts-backups/ and never use ~/.zshrc.bak
  - Stream: 1
  - Requirements: [1.1](requirements.md#1.1), [1.3](requirements.md#1.3)

- [x] 3. Implement sync-config.sh link_file, backup_path, link table, repo-layout guard <!-- id:pp5y8f6 -->
  - macos/sync-config.sh; SCRIPT_DIR resolution like agentic-coding/scripts/sync-claude.sh; no sudo
  - Link the 4 enumerated targets: ~/.aliases.zsh, ~/.vimrc, ~/.zshrc.workscripts->zshrc.snippet, ~/.local/bin/skup->macos/skup
  - backup_path: ~/.workscripts-backups/<base>.<UTC ts>.bak with counter on collision
  - Exit non-zero with plain message if expected macos/ siblings missing
  - Blocked-by: pp5y8f5 (Write tests for link_file and backup_path)
  - Stream: 1
  - Requirements: [1.1](requirements.md#1.1), [1.3](requirements.md#1.3), [1.4](requirements.md#1.4)

- [x] 4. Write tests for write_managed_block <!-- id:pp5y8f7 -->
  - Splice managed block immediately above first source $ZSH/oh-my-zsh.sh; strip-then-reinsert is idempotent (one marker pair, byte-identical second run); PATH line is case-guarded (no-op when ~/.local/bin already on PATH); file with no oh-my-zsh line -> block inserted at top; content outside markers preserved
  - Blocked-by: pp5y8f6 (Implement sync-config.sh link_file, backup_path, link table, repo-layout guard)
  - Stream: 1
  - Requirements: [3.2](requirements.md#3.2)

- [x] 5. Implement write_managed_block in sync-config.sh <!-- id:pp5y8f8 -->
  - Blocked-by: pp5y8f7 (Write tests for write_managed_block)
  - Stream: 1
  - Requirements: [3.2](requirements.md#3.2)

- [x] 6. Write tests for anchor-range migration and drift removal <!-- id:pp5y8f9 -->
  - Deletes the contiguous range from the # Added from troobit/workscripts setup script marker down to and including the export PATH=$(brew --prefix python)... line; a missing anchor -> skip and report, no deletion; whole-file backup taken before edit; removes the 4 captured drift lines (alias t, alias cld, corrupted alias tk, lorb()) by guarded exact match; leaves PRISMPATH, cppr, and /Users/r machine paths untouched
  - Blocked-by: pp5y8f8 (Implement write_managed_block in sync-config.sh)
  - Stream: 1
  - Requirements: [3.3](requirements.md#3.3), [4.2](requirements.md#4.2)

- [x] 7. Implement migration + drift-line removal; add captured aliases; wire sync-config main flow <!-- id:pp5y8fa -->
  - Implement anchor-range migration and guarded removal of the 4 drift lines
  - Add to macos/aliases.zsh: alias t=tmux, alias cld=claude --dangerously-skip-permissions, lorb() as in live zshrc, and the FIXED alias tk=tmux kill-session -t (correcting the corrupted ~ form)
  - sync-config.sh main runs: link table -> migration -> write_managed_block
  - Blocked-by: pp5y8f9 (Write tests for anchor-range migration and drift removal)
  - Stream: 1
  - Requirements: [3.3](requirements.md#3.3), [4.1](requirements.md#4.1), [4.2](requirements.md#4.2)

- [x] 8. Create macos/Brewfile from new-mac.sh package arrays <!-- id:pp5y8fb -->
  - formulae -> brew "x", casks -> cask "y", Magnet -> mas "Magnet", id: 441258766
  - Data/config task, no preceding test
  - Stream: 1
  - Requirements: [2.1](requirements.md#2.1)

- [x] 9. Update new-mac.sh: brew bundle install, call sync-config.sh, add --local gating <!-- id:pp5y8fc -->
  - Replace install_packages formulae/cask arrays with brew bundle --file macos/Brewfile || true then brew bundle check --file ... --verbose for the failure summary; do NOT pass --no-lock (removed from modern brew)
  - Replace the curl+append shell-config section (zshrc/aliases download/append blocks) with a call to macos/sync-config.sh
  - Add a LOCAL guard (--local sets LOCAL=1) that skips the interactive read/SSH/gh phase, sudo -v + the sudo keep-alive loop and its EXIT trap, and all sudo/defaults/pmset/systemsetup/Dock/login-item sections; keep the tee SETUP.log logging (home-only)
  - Wiring task, no preceding test
  - Blocked-by: pp5y8fa (Implement migration + drift-line removal; add captured aliases; wire sync-config main flow), pp5y8fb (Create macos/Brewfile from new-mac.sh package arrays)
  - Stream: 1
  - Requirements: [2.1](requirements.md#2.1), [2.2](requirements.md#2.2), [2.4](requirements.md#2.4), [3.4](requirements.md#3.4), [3.6](requirements.md#3.6), [6.1](requirements.md#6.1), [6.2](requirements.md#6.2)

## skup command

- [x] 10. Write tests for skup.conf parser <!-- id:pp5y8fd -->
  - macos/tests/skup-conf.sh: value is text after the first =, trimmed; only full-line # are comments (a # inside a value is kept); parser uses no eval; ~ expanded only for repos_root via ${v/#~/$HOME}; key-presence recorded separately from empty value
  - Stream: 2
  - Requirements: [5.2](requirements.md#5.2)

- [x] 11. Implement skup.conf parser in macos/skup <!-- id:pp5y8fe -->
  - Blocked-by: pp5y8fd (Write tests for skup.conf parser)
  - Stream: 2
  - Requirements: [5.2](requirements.md#5.2)

- [x] 12. Write tests for start_cmd detection <!-- id:pp5y8ff -->
  - cmd.<repo> declared (even empty value) -> use it / shell-only, no detection; else Makefile with a ^dev: target -> make dev; else package.json with .scripts.dev -> pnpm dev; else none; fixtures covering make-dev, pnpm-dev, override (toes=make web), shell-only (brandme, finance)
  - Blocked-by: pp5y8fe (Implement skup.conf parser in macos/skup)
  - Stream: 2
  - Requirements: [5.3](requirements.md#5.3)

- [x] 13. Implement start_cmd detection in skup <!-- id:pp5y8fg -->
  - Blocked-by: pp5y8ff (Write tests for start_cmd detection)
  - Stream: 2
  - Requirements: [5.3](requirements.md#5.3)

- [x] 14. Write tests for server_alive liveness detection <!-- id:pp5y8fh -->
  - server_alive uses pgrep -P on the pane_pid from tmux list-panes -t repo:server -F #{pane_pid} | head -1; a pane with a live child = alive, an idle shell = dead
  - Blocked-by: pp5y8fg (Implement start_cmd detection in skup)
  - Stream: 2
  - Requirements: [5.8](requirements.md#5.8)

- [x] 15. Implement skup session create/reuse, liveness restart, attach/switch, tag resolution <!-- id:pp5y8fi -->
  - Per repo in config order: skip+warn if dir missing; create tmux new-session -d -s repo -c path -n shell plus a server window running the start_cmd via send-keys when one exists; on reuse restart the server window if not server_alive; attach to first repo, or tmux switch-client when already inside $TMUX
  - Bare skup -> default set; unknown tag -> exit non-zero listing known tags
  - Blocked-by: pp5y8fh (Write tests for server_alive liveness detection)
  - Stream: 2
  - Requirements: [5.1](requirements.md#5.1), [5.4](requirements.md#5.4), [5.5](requirements.md#5.5), [5.6](requirements.md#5.6), [5.7](requirements.md#5.7), [5.9](requirements.md#5.9), [5.10](requirements.md#5.10)

- [x] 16. Create macos/skup.conf with default set, tags, and overrides <!-- id:pp5y8fj -->
  - default, tag.feature (sdd-ui rtob), tag.billing (toes finance), tag.client (sanarte brandme); cmd.toes = make web; cmd.brandme = (empty, shell-only); repos_root = ~/repos
  - Data/config task, no preceding test
  - Stream: 2
  - Requirements: [5.2](requirements.md#5.2)

## Verification

- [ ] 17. Extend verify-setup.sh with converged-state assertions <!-- id:pp5y8fk -->
  - Assert the 4 managed links are symlinks pointing into the repo; ~/.zshrc has exactly one managed marker pair and sources ~/.zshrc.workscripts; no legacy # Added from troobit/workscripts setup script marker remains; ~/.local/bin/skup is executable; skup.conf parses and each default/tag repo resolves under repos_root or is reported
  - Drift content assertions: t->tmux, tk->tmux kill-session -t (fixed form, not corrupted), cld and lorb defined; PRISMPATH/cppr still in ~/.zshrc and absent from repo files
  - This task is itself the test harness extension
  - Blocked-by: pp5y8fa (Implement migration + drift-line removal; add captured aliases; wire sync-config main flow), pp5y8fc (Update new-mac.sh: brew bundle install, call sync-config.sh, add --local gating), pp5y8fi (Implement skup session create/reuse, liveness restart, attach/switch, tag resolution), pp5y8fj (Create macos/skup.conf with default set, tags, and overrides)
  - Stream: 1
  - Requirements: [3.5](requirements.md#3.5), [4.1](requirements.md#4.1)

- [ ] 18. Write the twice-run idempotency test <!-- id:pp5y8fl -->
  - macos/tests/idempotency.sh: run sync-config.sh twice; assert the second run creates no new backup and leaves ~/.zshrc byte-identical to after the first run
  - Blocked-by: pp5y8fa (Implement migration + drift-line removal; add captured aliases; wire sync-config main flow)
  - Stream: 1
  - Requirements: [3.5](requirements.md#3.5), [3.7](requirements.md#3.7)
