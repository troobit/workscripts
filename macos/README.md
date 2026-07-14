# macos/

Scripts and dotfiles for setting up and verifying a Mac.

> **Do not move or rename files in this directory.** `new-mac.sh` bootstraps
> over HTTPS from `https://raw.githubusercontent.com/troobit/workscripts/main/macos/...`
> and downloads `vimrc`, `zshrc`, and `aliases.zsh` by those exact raw URLs —
> the paths are load-bearing.

## Layout

| File | Purpose |
|------|---------|
| `new-mac.sh` | Full new-Mac setup. Two phases: an **interactive phase** (Xcode CLT, Homebrew, GitHub auth, SSH key, sudo) followed by an **unattended phase** (packages, system settings, Dock, headless config, repos, tools) logged to `~/SETUP.log`. Safe to re-run. |
| `verify-setup.sh` | Post-run verification — checks Dock, preferences, power, headless operation (SSH/Tailscale/sleep), packages, and shell config. |
| `zshrc`, `aliases.zsh`, `vimrc` | Shell/editor config deployed by the setup script (fetched by raw URL). |
| `agnoster.zsh-theme` | Zsh theme used by the zshrc. |
| `gitconfig`, `gitconfig_subdir` | Reference git configs (the script generates `~/.gitconfig` itself). |
| `iterm2-prefs.plist` | iTerm2 preferences imported by the setup script. |
| `docker-compose.yml` | Reference compose file for the podman/podman-compose setup. |
| `vsc-shortcuts.md` | VS Code shortcut cheat sheet. |
| `bash/` | Miscellaneous bash snippets. |

## Guides

- [New Mac Setup Guide](../docs/new-mac-guide.md) — what the script installs
  and configures, prerequisites, post-setup steps, troubleshooting.
- [Headless Mac Server Guide](../docs/new-mac-localhost.md) — running the
  machine always-on in clamshell mode: SSH/Tailscale access, tmux, file
  copying, git pushes, long-lived processes.

## Conventions

- Scripts target the macOS default bash 3.2 (no associative arrays, no
  `${var,,}` etc.).
- `new-mac.sh` runs under `set -e`: any command that may legitimately fail
  must be guarded with `if`/`||` so one failure cannot skip later sections.
- Every config write is idempotent — guarded by an existence check or a
  grep marker — so re-running the script never duplicates lines.
- Quality gates: `shellcheck` and `bash -n` on both scripts.
