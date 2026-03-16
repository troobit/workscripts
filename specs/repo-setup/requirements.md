# Requirements: Repository Setup Automation

## Introduction

This feature extends the `macos/new-mac.sh` script to add developer repository setup. The existing script already handles prerequisites (Xcode tools, Homebrew, Oh-My-Zsh, packages). This enhancement adds:
- GitHub CLI and Go installation
- SSH key generation and GitHub registration
- Git configuration from template
- Repository cloning (workscripts, rune, orbit, agentic-coding)
- Claude Code skills symlink setup
- Go tool installation (rune, orbit)

The script can be downloaded via raw GitHub URL and run on a fresh Mac with minimal human interaction after initial setup.

---

## Requirements

### 1. Additional Package Installation

**User Story:** As a developer setting up a new Mac, I want GitHub CLI and Go to be installed via Homebrew, so that I can manage GitHub authentication and build Go tools.

**Acceptance Criteria:**

1. <a name="1.1"></a>The script SHALL add `gh` (GitHub CLI) to the brew packages list
2. <a name="1.2"></a>The script SHALL add `go` to the brew packages list
3. <a name="1.3"></a>The script SHALL install these packages as part of the existing brew install step
4. <a name="1.4"></a>The script SHALL log whether each package was installed or already present

---

### 2. SSH Key Setup

**User Story:** As a developer setting up a new Mac, I want SSH keys to be generated and added to GitHub automatically, so that I can authenticate with GitHub for repository operations.

**Acceptance Criteria:**

1. <a name="2.1"></a>The script SHALL check if an SSH key exists at `~/.ssh/github`
2. <a name="2.2"></a>The script SHALL skip key generation if `~/.ssh/github` already exists
3. <a name="2.3"></a>The script SHALL prompt the user for their GitHub email address if no key exists
4. <a name="2.4"></a>The script SHALL generate a new ED25519 SSH key using `ssh-keygen -t ed25519 -C <email> -f ~/.ssh/github -N ""`
5. <a name="2.5"></a>The script SHALL start ssh-agent if not running using `eval "$(ssh-agent -s)"`
6. <a name="2.6"></a>The script SHALL add the SSH key to ssh-agent using `ssh-add ~/.ssh/github`
7. <a name="2.7"></a>The script SHALL authenticate with GitHub using `gh auth login` if not already authenticated
8. <a name="2.8"></a>The script SHALL upload the public key to GitHub using `gh ssh-key add ~/.ssh/github.pub --title "MacBook-$(date +%Y%m%d)"`
9. <a name="2.9"></a>The script SHALL test the SSH connection with `ssh -T git@github.com -i ~/.ssh/github`
10. <a name="2.10"></a>The script SHALL log each step to stdout (key generation, upload, verification)
11. <a name="2.11"></a>The script SHALL exit with error if SSH key upload or verification fails

---

### 3. Git Configuration Setup

**User Story:** As a developer setting up a new Mac, I want my Git configuration to be set up from the repository template with my personal details, so that my commits are properly attributed.

**Acceptance Criteria:**

1. <a name="3.1"></a>The script SHALL check if `~/.gitconfig` already exists
2. <a name="3.2"></a>The script SHALL skip gitconfig setup if it already exists (assume pre-configured)
3. <a name="3.3"></a>The script SHALL prompt the user for their name (e.g., "Ronan O'Brien") if gitconfig doesn't exist
4. <a name="3.4"></a>The script SHALL prompt the user for their GitHub email (e.g., "18034798+troobit@users.noreply.github.com") if gitconfig doesn't exist
5. <a name="3.5"></a>The script SHALL download the `macos/gitconfig` template using curl from raw GitHub URL
6. <a name="3.6"></a>The script SHALL replace the placeholder name "Ronan" with user-provided name
7. <a name="3.7"></a>The script SHALL replace the placeholder email "ronan@place.com" with user-provided email
8. <a name="3.8"></a>The script SHALL write the configured gitconfig to `~/.gitconfig`
9. <a name="3.9"></a>The script SHALL log to stdout whether gitconfig was created or already existed

---

### 4. Repository Directory Creation

**User Story:** As a developer setting up a new Mac, I want a standardized `~/repos/` directory created automatically, so that all my development repositories are organized in a consistent location.

**Acceptance Criteria:**

1. <a name="4.1"></a>The script SHALL create a `~/repos/` directory if it does not exist
2. <a name="4.2"></a>The script SHALL skip directory creation if `~/repos/` already exists
3. <a name="4.3"></a>The script SHALL use appropriate permissions (user read/write/execute) for the directory
4. <a name="4.4"></a>The script SHALL log a message indicating whether the directory was created or already existed

---

### 5. Repository Cloning via SSH

**User Story:** As a developer, I want the script to clone essential repositories (workscripts, rune, orbit, agentic-coding) into `~/repos/`, so that my development environment is ready immediately.

**Acceptance Criteria:**

1. <a name="5.1"></a>The script SHALL clone repositories using SSH protocol (git@github.com:org/repo.git)
2. <a name="5.2"></a>The script SHALL clone `troobit/workscripts` into `~/repos/workscripts`
3. <a name="5.3"></a>The script SHALL clone `ArjenSchwarz/rune` into `~/repos/rune`
4. <a name="5.4"></a>The script SHALL clone `ArjenSchwarz/orbit` into `~/repos/orbit`
5. <a name="5.5"></a>The script SHALL clone `ArjenSchwarz/agentic-coding` into `~/repos/agentic-coding`
6. <a name="5.6"></a>The script SHALL skip cloning if the repository directory already exists and contains a .git subdirectory
7. <a name="5.7"></a>The script SHALL use `|| echo "Failed to clone <repo>"` pattern to continue on clone failure
8. <a name="5.8"></a>The script SHALL log each clone operation with the repository name and status (cloned/skipped) to stdout

---

### 6. Claude Code Skills Symlink

**User Story:** As a developer, I want Claude Code skills from the agentic-coding repository to be available via symlink, so that I can use custom skills without manual setup.

**Acceptance Criteria:**

1. <a name="6.1"></a>The script SHALL create the `~/.claude` directory if it does not exist
2. <a name="6.2"></a>The script SHALL check if `~/.claude/skills` already exists
3. <a name="6.3"></a>The script SHALL skip symlink creation if `~/.claude/skills` is already a symlink pointing to `~/repos/agentic-coding/claude/skills`
4. <a name="6.4"></a>The script SHALL create a symlink from `~/.claude/skills` to `~/repos/agentic-coding/claude/skills` if it doesn't exist
5. <a name="6.5"></a>The script SHALL use `ln -s ~/repos/agentic-coding/claude/skills ~/.claude/skills` to create the symlink
6. <a name="6.6"></a>The script SHALL log whether the symlink was created or already existed
7. <a name="6.7"></a>The script SHALL skip symlink creation if agentic-coding repository was not successfully cloned
8. <a name="6.8"></a>The script SHALL warn to stderr if `~/.claude/skills` exists but is not a symlink or points elsewhere

---

### 7. Go Tool Installation

**User Story:** As a developer, I want the rune and orbit tools to be built and installed automatically, so that they are immediately available for use in my development environment.

**Acceptance Criteria:**

1. <a name="7.1"></a>The script SHALL install the rune tool after successfully cloning ArjenSchwarz/rune
2. <a name="7.2"></a>The script SHALL install the orbit tool after successfully cloning ArjenSchwarz/orbit
3. <a name="7.3"></a>The script SHALL attempt installation using `make install` if a Makefile exists in the repository root
4. <a name="7.4"></a>The script SHALL fall back to `go install` if no Makefile exists or if `make install` fails
5. <a name="7.5"></a>The script SHALL run tool installation from within the repository directory (e.g., `cd ~/repos/rune && make install`)
6. <a name="7.6"></a>The script SHALL skip tool installation if the repository was not successfully cloned
7. <a name="7.7"></a>The script SHALL log each tool installation attempt to stdout with success or failure status
8. <a name="7.8"></a>The script SHALL continue execution if one tool fails to install

---

### 8. User Input Collection

**User Story:** As a developer setting up a new Mac, I want to provide minimal input after downloading the script, so that setup proceeds unattended after initial prompts.

**Acceptance Criteria:**

1. <a name="8.1"></a>The script SHALL collect all user input after existing setup completes (after Oh-My-Zsh and packages)
2. <a name="8.2"></a>The script SHALL prompt for GitHub email (used for both SSH key and gitconfig if same)
3. <a name="8.3"></a>The script SHALL prompt for Git user name for gitconfig
4. <a name="8.4"></a>The script SHALL use `read -p` with clear prompts (e.g., "Enter your GitHub email: ")
5. <a name="8.5"></a>The script SHALL validate that user input is not empty
6. <a name="8.6"></a>The script SHALL re-prompt if validation fails
7. <a name="8.7"></a>The script SHALL require only 2 inputs: GitHub email and Git name (minimize prompts)

---

### 9. Error Handling and Resilience

**User Story:** As a developer, I want the script to handle failures gracefully, so that critical failures stop setup while non-critical failures allow continuation.

**Acceptance Criteria:**

1. <a name="9.1"></a>The script SHALL exit immediately if SSH key generation or upload fails (critical operation)
2. <a name="9.2"></a>The script SHALL exit immediately if Git configuration setup fails (critical operation)
3. <a name="9.3"></a>The script SHALL continue execution if one repository fails to clone (non-critical)
4. <a name="9.4"></a>The script SHALL continue execution if symlink creation fails (non-critical)
5. <a name="9.5"></a>The script SHALL continue execution if one tool fails to install (non-critical)
6. <a name="9.6"></a>The script SHALL log clear error messages to stderr when operations fail
7. <a name="9.7"></a>The script SHALL use conditional logic (e.g., `|| echo`) for non-critical operations to prevent set -e exit
8. <a name="9.8"></a>The script SHALL log a summary at the end to stdout showing: "✅ Setup complete! Successfully set up X/Y repositories, symlink, and X/Y tools"

---

### 10. macOS Compatibility

**User Story:** As a developer using a modern Mac, I want the script to work on both Intel and Apple Silicon Macs, so that the setup process is consistent regardless of hardware.

**Acceptance Criteria:**

1. <a name="10.1"></a>The script SHALL work on macOS 12 (Monterey) and later
2. <a name="10.2"></a>The script SHALL work on both Intel and Apple Silicon architectures
3. <a name="10.3"></a>The script SHALL detect Apple Silicon and use `/opt/homebrew` paths appropriately
4. <a name="10.4"></a>The script SHALL use bash as the interpreter (#!/bin/bash)

---

### 11. Integration with Existing Setup Script

**User Story:** As a developer, I want the repository setup to be integrated into the existing `new-mac.sh` script, so that I have a single entry point for all Mac setup tasks.

**Acceptance Criteria:**

1. <a name="11.1"></a>The new code SHALL be added to the existing `macos/new-mac.sh` file before the final "Setup complete" message
2. <a name="11.2"></a>The setup flow SHALL be:
   - **Existing:** Xcode tools, Homebrew, Homebrew PATH setup, brew update
   - **Modified:** Add `gh` and `go` to brew packages list (line 54)
   - **Existing:** Install packages, Oh-My-Zsh, zsh plugins, .vimrc, .zshrc
   - **NEW:** User input collection (minimize to 2 prompts: email, name)
   - **NEW:** SSH key generation and GitHub upload
   - **NEW:** Git configuration setup
   - **NEW:** ~/repos/ directory creation
   - **NEW:** Repository cloning (workscripts, rune, orbit, agentic-coding)
   - **NEW:** Claude Code skills symlink creation
   - **NEW:** Go tool installation (rune, orbit)
   - **Existing:** "✅ Setup complete!" message
3. <a name="11.3"></a>The new code SHALL follow the same patterns as existing code:
   - Use `if [ ! -f ], if [ ! -d ], if [ ! -L ]` for idempotency checks
   - Use `|| echo "..."` for non-critical operations
   - Use emoji prefixes for output (🚀, ✅, ❌)
   - Use `echo` for logging
4. <a name="11.4"></a>The new code SHALL maintain the script's `set -e` behavior
5. <a name="11.5"></a>Critical operations (SSH key, gitconfig) SHALL exit on failure (rely on set -e)
6. <a name="11.6"></a>Non-critical operations (repo cloning, symlink, tool install) SHALL use `|| echo` to continue on failure

---

## Out of Scope

The following items are explicitly out of scope for this feature:

- **Prerequisites already handled:** Xcode tools, Homebrew, Oh-My-Zsh, git, brew packages (handled by existing script)
- **Script distribution:** Downloading script via curl (user responsibility)
- **Apple ecosystem registration:** iCloud sign-in, Apple ID setup (manual step before running script)
- **Full disk access permissions:** macOS prompts for iTerm2, VSCode, etc. (user approves via System Preferences)
- **Updating existing repositories:** No `git pull` or `git fetch` on subsequent runs
- **SSH key passphrases:** Keys generated without passphrase for automation
- **SSH config file:** Relies on gitconfig `core.sshCommand` instead
- **Installing dependencies for workscripts:** Shell scripts don't require building
- **Tools beyond rune and orbit:** Hardcoded to these two Go tools (agentic-coding provides skills, not a binary tool)
- **Custom repository lists:** Hardcoded to four repos (workscripts, rune, orbit, agentic-coding)
- **Retry logic for network failures:** May be added in future iteration
- **Multiple GitHub accounts:** Single SSH key and GitHub account only
