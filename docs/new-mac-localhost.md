# Headless Mac Server Guide

How to set up a Mac as an always-on headless machine — lid closed in
clamshell mode, reachable over SSH and Tailscale, running long-lived tooling
so your primary machine can be switched off.

For the full walkthrough of everything `new-mac.sh` installs and configures,
see the [New Mac Setup Guide](new-mac-guide.md). This guide covers only the
headless workflow.

## 1. Bootstrap

On the fresh Mac (SSH keys don't exist yet, so fetch over HTTPS):

```bash
curl -fsSL https://raw.githubusercontent.com/troobit/workscripts/main/macos/new-mac.sh -o /tmp/new-mac.sh
chmod +x /tmp/new-mac.sh
bash /tmp/new-mac.sh
```

## 2. Interactive phase

Stay at the keyboard until the script prints
`🚀 Unattended phase starting — you can walk away now`. You will:

1. Approve the Xcode Command Line Tools dialog (if prompted)
2. Enter your GitHub noreply email and full name
3. Complete `gh auth login` in the browser (SSH key is generated and uploaded)
4. Enter your sudo password (a keep-alive maintains it for the rest of the run)

The unattended phase then installs packages, applies system settings, and —
for headless use — enables Remote Login (SSH), disables sleep entirely
(`pmset -a disablesleep 1`, so the lid can stay closed), and turns on
auto-restart after power failure. All output lands in `~/SETUP.log`.

## 3. Manual sign-ins

The script prints this checklist at the end of the run:

- [ ] **Tailscale** — open Tailscale.app, sign in to your tailnet (browser)
- [ ] **Claude Code** — run `claude`; the first run opens a browser login
- [ ] **App Store** — sign in with your Apple ID, then `mas install 441258766` (Magnet)
- [x] **GitHub** — already done in the interactive phase (`gh auth status` to verify)

Complete these while you still have the lid open. Once Tailscale is signed
in and SSH works, you can close the lid and go fully headless.

## 4. Verify, then close the lid

```bash
cd ~/repos/workscripts
bash macos/verify-setup.sh
```

The `Headless Operation` section must pass: Remote Login on, Tailscale
installed and logged in, `SleepDisabled 1`, auto-restart on. Then plug into
AC power, close the lid, and confirm the machine still answers ping/SSH.

## 5. Connecting from another Mac

### Finding the machine

- **Local network**: macOS advertises `<hostname>.local` via Bonjour —
  check with `hostname` on the server, or use its LAN IP
  (`ipconfig getifaddr en0`).
- **Tailscale**: use the MagicDNS name shown by `tailscale status` (e.g.
  `server.tailnet-name.ts.net`) or the 100.x.y.z address. This works from
  anywhere, not just the LAN.

### SSH with a persistent session

```bash
ssh user@server.local                 # LAN
ssh user@server.tailnet-name.ts.net   # via Tailscale, from anywhere
```

Run everything inside tmux so sessions survive disconnects:

```bash
tmux new -A -s main    # attach to "main", creating it if needed
```

Detach with `Ctrl-b d`; reconnecting with the same command drops you back
into the running session.

## 6. Copying files

Both directions, from your primary machine:

```bash
# push a file to the server
scp ./file.txt user@server.local:~/inbox/

# pull a file from the server
scp user@server.local:~/outbox/result.zip .

# sync a directory to the server (repeatable, only transfers changes)
rsync -avz ./project/ user@server.local:~/projects/project/

# sync results back
rsync -avz user@server.local:~/projects/project/build/ ./build/
```

Over Tailscale, replace `server.local` with the MagicDNS name. For ad-hoc
transfers between Macs, Tailscale's `taildrop` also works:
`tailscale file cp ./file.txt server:`.

## 7. Pushing to repos on the machine

The setup script clones repos into `~/repos/` on the server. To push work
from your primary machine directly to a repo there, add the server as a git
remote (pushing to a checked-out branch needs a config tweak on the server):

```bash
# on the server, allow pushes to the checked-out branch
git -C ~/repos/myrepo config receive.denyCurrentBranch updateInstead

# on your primary machine
git remote add server user@server.local:repos/myrepo
git push server main
```

`updateInstead` updates the server's working tree on push as long as it is
clean. Alternatively keep GitHub as the hub: push to origin from your
machine and `git pull` on the server inside tmux.

## 8. Long-lived processes

### tmux (simplest)

Start the process in a named tmux session and detach — it keeps running
after you disconnect:

```bash
tmux new -A -s sdd-ui
sdd-ui        # or any long-lived process
# Ctrl-b d to detach
```

### launchd (survives reboots)

For processes that must come back after a restart (the machine auto-restarts
on power failure), use a LaunchAgent. Example
`~/Library/LaunchAgents/com.user.sdd-ui.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.user.sdd-ui</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Users/USERNAME/go/bin/sdd-ui</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/tmp/sdd-ui.log</string>
  <key>StandardErrorPath</key><string>/tmp/sdd-ui.err</string>
</dict>
</plist>
```

```bash
launchctl load ~/Library/LaunchAgents/com.user.sdd-ui.plist    # enable
launchctl unload ~/Library/LaunchAgents/com.user.sdd-ui.plist  # disable
```

Note: LaunchAgents run at user login. For a headless machine, enable
automatic login (System Settings → Users & Groups → Automatically log in)
so agents start after an unattended reboot, or use a LaunchDaemon in
`/Library/LaunchDaemons/` for pre-login services.

## Troubleshooting

- **Machine sleeps with lid closed** — check `pmset -g | grep SleepDisabled`
  is `1`; re-run `sudo pmset -a disablesleep 1`.
- **SSH refused** — `sudo systemsetup -getremotelogin` must report `On`;
  re-enable with `sudo systemsetup -setremotelogin on`.
- **Unreachable via Tailscale** — open Tailscale.app and check the sign-in;
  `tailscale status` from another device shows whether the node is online.
- **Setup issues** — see `~/SETUP.log` and the
  [New Mac Setup Guide troubleshooting section](new-mac-guide.md#troubleshooting).
