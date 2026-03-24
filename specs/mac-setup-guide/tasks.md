---
references:
    - specs/mac-setup-guide/smolspec.md
---
# mac-setup-guide

## Phase A: Guide Scaffolding

- [x] 1. Create docs/ directory and scaffold guide with Quick Start, Prerequisites, and Getting Started sections <!-- id:lew5h9d -->
  - Create docs/ directory
  - Create docs/new-mac-guide.md with document title and Quick Start section (3-4 lines of curl/run commands)
  - Add Prerequisites section: macOS 15+ (Sequoia) and Apple ID signed into App Store and internet connection
  - Add Getting Started section header for bootstrap content
  - Stream: 1
  - References: macos/new-mac.sh, specs/mac-setup-guide/smolspec.md

- [x] 2. Document bootstrap problem and initial download commands <!-- id:lew5h9e -->
  - Bootstrap is curl to the raw script URL (no SSH keys exist yet on a fresh Mac)
  - Provide exact fenced code block: curl the raw file from github.com/troobit/workscripts then pipe or run
  - SSH key generation is the first meaningful interactive step after automated Xcode CLT/Homebrew/gh bootstrap
  - Verification: curl command points to valid raw URL and is syntactically correct
  - Blocked-by: lew5h9d (Create docs/ directory and scaffold guide with Quick Start, Prerequisites, and Getting Started sections)
  - Stream: 1
  - References: macos/new-mac.sh

## Phase B: Core Content

- [x] 3. Document the two-phase structure (interactive and unattended) with what each phase does <!-- id:lew5h9f -->
  - Document interactive phase: first the script auto-installs Xcode CLT and Homebrew and gh then prompts for GitHub noreply email and full name then generates SSH key and authenticates with GitHub via gh then prompts for sudo password
  - Instruct users to use their GitHub noreply email (e.g. 12345678+username@users.noreply.github.com) found at GitHub Settings → Emails → Keep my email addresses private — this is used for both ssh-keygen -C and .gitconfig [user] email
  - Document unattended phase: list what happens so users know when they can walk away
  - Mention ~/SETUP.log as the log file for debugging unattended phase issues
  - Verification: both phases accurately reflect the actual script flow and noreply email guidance is clear
  - Blocked-by: lew5h9d (Create docs/ directory and scaffold guide with Quick Start, Prerequisites, and Getting Started sections)
  - Stream: 1
  - References: macos/new-mac.sh

- [x] 4. Add software inventory by category (default, home, work, MAS) with descriptions for non-obvious tools <!-- id:lew5h9g -->
  - List all software by category: default_packages and home_packages and work_packages and Mac App Store
  - Include brief descriptions for non-obvious tools: bluesnooze noTunes dockutil lychee cloudflared ykman codelayer yubico-authenticator uv mas raycast
  - Explain how to opt into work_packages (Slack and Teams and Terraform) which are excluded by default
  - Verification: every package in the script arrays appears in the guide
  - Blocked-by: lew5h9f (Document the two-phase structure (interactive and unattended) with what each phase does)
  - Stream: 1
  - References: macos/new-mac.sh

- [x] 5. Add What Gets Configured summary table mapping categories to script setup actions <!-- id:lew5h9h -->
  - Create summary table mapping categories to what the script configures
  - Categories: Dock and system preferences and power and browser and login items and shell and Git and repos and tools
  - Reference script file paths relative to repo root for each category
  - Verification: table covers all major configuration areas from the script
  - Blocked-by: lew5h9f (Document the two-phase structure (interactive and unattended) with what each phase does)
  - Stream: 1
  - References: macos/new-mac.sh, macos/verify-setup.sh, macos/aliases.zsh, macos/zshrc, macos/vimrc

- [x] 6. Document all post-setup manual steps (app logins, license activations, config syncs) <!-- id:lew5h9i -->
  - Document all manual steps: terminal restart and App Store sign-in for Magnet and Magnet license activation and Raycast configuration and NordVPN login and Bitwarden login and Tailscale login and Dropbox login and Spotify login and Google Drive login and VS Code Settings Sync activation and Logi Options+ device pairing and .gitconfig placeholder editing (SPECIFIC_FOLDER) and optionally installing full Xcode for Simulator.app
  - Verification: every post-setup item from the smolspec is included
  - Blocked-by: lew5h9g (Add software inventory by category (default, home, work, MAS) with descriptions for non-obvious tools), obvious, obvious, obvious, obvious, obvious, obvious, obvious, obvious
  - Stream: 1
  - References: specs/mac-setup-guide/smolspec.md, specs/mac-env-setup/decision_log.md

## Phase C: Verification and Polish

- [x] 7. Add verification command section, troubleshooting section, and customisation points <!-- id:lew5h9j -->
  - Add verification command: bash macos/verify-setup.sh and explain its output
  - Add troubleshooting section: Homebrew PATH on Apple Silicon and mas requiring App Store sign-in and SSH key already exists and ~/SETUP.log for debugging
  - Add customisation points section (3-5 bullets): arrays/variables a user would edit with file paths
  - Verification: troubleshooting covers all items from smolspec SHOULD requirements
  - Blocked-by: lew5h9i (Document all post-setup manual steps (app logins, license activations, config syncs)), license, license, license, license, license, license, license, license
  - Stream: 1
  - References: macos/verify-setup.sh, macos/new-mac.sh

- [x] 8. Review guide against all smolspec MUST/SHOULD/MAY requirements and verify completeness <!-- id:lew5h9k -->
  - Check every MUST requirement from smolspec.md is addressed in the guide
  - Check every SHOULD requirement is addressed or explicitly noted as deferred
  - Check every MAY requirement is addressed if appropriate
  - Verify all script file paths referenced: macos/new-mac.sh and macos/verify-setup.sh and macos/aliases.zsh and macos/zshrc and macos/vimrc and macos/docker-compose.yml and macos/iterm2-prefs.plist
  - Verify guide includes Last verified date and source-of-truth note
  - Verify guide reads coherently end-to-end and stays within 300-500 lines target
  - Blocked-by: lew5h9e (Document bootstrap problem and initial download commands), lew5h9f (Document the two-phase structure (interactive and unattended) with what each phase does), lew5h9g (Add software inventory by category (default, home, work, MAS) with descriptions for non-obvious tools), obvious, obvious, obvious, obvious, obvious, obvious, obvious, obvious, lew5h9h (Add What Gets Configured summary table mapping categories to script setup actions), lew5h9i (Document all post-setup manual steps (app logins, license activations, config syncs)), license, license, license, license, license, license, license, license, lew5h9j (Add verification command section, troubleshooting section, and customisation points)
  - Stream: 1
  - References: specs/mac-setup-guide/smolspec.md
