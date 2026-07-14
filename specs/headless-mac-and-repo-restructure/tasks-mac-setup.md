---
references:
    - prd.md
---
# Headless Mac setup and repo restructure — mac-setup

## Script audit and fixes

- [x] 1. Audit new-mac.sh and verify-setup.sh; fix defects and shellcheck findings <!-- id:4w9cwsr -->
  - Fix echo "\n" bashism (new-mac.sh:209) writing literal \n into ~/.zshrc
  - Review set -e + exec tee + background sudo keep-alive interplay and Swift heredoc failure path
  - shellcheck clean on both scripts (warnings triaged or suppressed with reason)

- [x] 2. Verify safe re-run: second run completes without error or duplicate config lines <!-- id:4w9cwss -->
  - No duplicate lines in ~/.zshrc or ~/.gitconfig on re-run
  - Document dry-run reasoning or VM check as evidence
  - Evidence (sandbox check): config-write blocks copied verbatim into a harness with HOME=sandbox and curl stubbed, run twice — .zshrc and .gitconfig byte-identical after run 2, no duplicate non-blank lines, no literal backslash-n line
  - Evidence (guard audit): .zshrc appends guarded by grep markers ("troobit/workscripts" written only after successful download; "source.*aliases.zsh"; "brew --prefix python"); .gitconfig/.vimrc/ssh-key/oh-my-zsh/plugin/repos/symlink writes all guarded by existence checks; brew install re-run on installed packages exits 0; dock section is remove-all-then-re-add (idempotent net state)
  - Evidence (no-abort audit): every unattended command that can legitimately fail is if/|| guarded so set -e cannot skip later sections; fixed unguarded kill/wait of the dialog handler (wait returned 143 and aborted the run mid-script)
  - Blocked-by: 4w9cwsr (Audit new-mac.sh and verify-setup.sh; fix defects and shellcheck findings)

## Headless capabilities

- [x] 3. Install and bring up Tailscale <!-- id:4w9cwst -->
  - Verify package name via brew info before use (tailscale-app was previously invalid)
  - Place tailscale login in interactive phase or post-run checklist
  - Stream: 1

- [x] 4. Enable Remote Login (SSH) idempotently <!-- id:4w9cwsu -->
  - sudo systemsetup -setremotelogin on or equivalent
  - Stream: 1

- [x] 5. Configure always-on clamshell power settings <!-- id:4w9cwsv -->
  - No sleep with lid closed on AC (e.g. pmset disablesleep) with explanatory comment
  - Auto-restart after power failure (systemsetup -setrestartpowerfailure on or pmset autorestart)
  - Stream: 1

- [x] 6. Consolidated manual sign-ins checklist (GitHub, Claude, Tailscale, App Store) <!-- id:4w9cwsw -->
  - Printed at end of run and repeated in the guide
  - Stream: 2

- [x] 7. Extend verify-setup.sh: remote login, Tailscale, always-on power checks <!-- id:4w9cwsx -->
  - Blocked-by: 4w9cwst (Install and bring up Tailscale), 4w9cwsu (Enable Remote Login SSH idempotently), 4w9cwsv (Configure always-on clamshell power settings)
  - Stream: 2

## Documentation

- [x] 8. Write docs/new-mac-localhost.md headless guide <!-- id:4w9cwsy -->
  - Bootstrap curl one-liner, interactive phase, sign-in checklist
  - Connect from another Mac: ssh, tmux new -A -s main; scp/rsync both directions; git push to machine
  - Long-lived processes via launchd/tmux (e.g. sdd-ui)
  - lychee --offline passes on local links
  - Blocked-by: 4w9cwst (Install and bring up Tailscale), 4w9cwsu (Enable Remote Login SSH idempotently), 4w9cwsv (Configure always-on clamshell power settings), 4w9cwsw (Consolidated manual sign-ins checklist GitHub, Claude, Tailscale, App Store)

- [x] 9. Reconcile with docs/new-mac-guide.md (single source, cross-link) <!-- id:4w9cwsz -->
  - Blocked-by: 4w9cwsy (Write docs/new-mac-localhost.md headless guide)

## Human verification

- [ ] 10. STOP — Run new-mac.sh on the physical new Mac and complete interactive sign-ins <!-- id:4w9cwt0 -->
  - Human step: physical machine, credentials, browser sign-ins. Deliverables end at code + docs.
  - Blocked-by: 4w9cwss (Verify safe re-run: second run completes without error or duplicate config lines), 4w9cwsy (Write docs/new-mac-localhost.md headless guide), 4w9cwsz (Reconcile with docs/new-mac-guide.md single source, cross-link)
