# Decision Log: Repository Setup Automation

## 2026-03-10

### Feature Naming
**Decision:** Use `repos-setup` as the feature name
**Rationale:** Clear, concise, and describes the core functionality
**Status:** Approved by user

### Branch Strategy
**Decision:** Create `feature/repos-setup` branch
**Rationale:** Standard feature branch naming convention
**Status:** Branch created and checked out

### Clone Protocol
**Decision:** Use SSH (git@github.com:...) instead of HTTPS
**Rationale:**
- User discussed SSH key setup optimization
- Better for frequent git operations
- Aligns with existing .gitconfig setup using `~/.ssh/github`
**Status:** Decided based on user context

### Idempotency Strategy
**Decision:** Skip cloning if repository directory already exists, without updating
**Rationale:**
- Safest approach - preserves local changes
- Avoids merge conflicts or destructive operations
- User explicitly requested idempotent behavior
**Status:** Specified in requirements 3.1-3.5

### Error Handling Approach
**Decision:** Continue on failure rather than stopping immediately
**Rationale:**
- Network issues shouldn't prevent other repos from cloning
- More resilient user experience
- Aligns with existing script patterns (e.g., brew install with `|| echo`)
**Status:** Specified in requirements 4.1-4.6

### Integration Approach
**Decision:** Extend existing `macos/new-mac.sh` rather than creating new script
**Rationale:**
- User explicitly stated "don't add new files"
- Single entry point for Mac setup
- Maintains consistency with existing patterns
**Status:** User requirement

### Repository List
**Decision:** Hard-code three repositories: troobit/workscripts, aschwarz/rune, azchwarz/orbit
**Rationale:**
- Simple, direct implementation
- No configuration management needed for initial version
- Can be enhanced later if needed
**Status:** User requirement

### Git Configuration Template Update
**Decision:** Move `sshCommand` from `[user]` to `[core]` section in macos/gitconfig template
**Rationale:**
- `sshCommand` is a core git setting, not a user setting
- Corrects configuration error in template
**Status:** ✅ Completed

### Repository Names Correction
**Decision:** Use `ArjenSchwarz/rune` and `ArjenSchwarz/orbit` (not aschwarz or azchwarz)
**Rationale:**
- User provided correct GitHub URLs
- https://github.com/ArjenSchwarz/orbit
- https://github.com/ArjenSchwarz/rune
**Status:** ✅ Updated in requirements

### Go Installation Requirement
**Decision:** Install Go via Homebrew as part of setup
**Rationale:**
- rune and orbit are Go tools that need to be built/installed
- Go not typically pre-installed on macOS
- Homebrew is already being used for package management
**Status:** ✅ Added as Requirement 3

### Go Tool Installation
**Decision:** Build and install rune and orbit tools after cloning, using make or go install
**Rationale:**
- Tools need to be ready to use after setup (not just cloned)
- Addresses design review feedback about "cloning but not ready to use"
- Prefer make install (if Makefile exists) with fallback to go install
**Status:** ✅ Added as Requirement 4

### Idempotency Validation Enhancement
**Decision:** Validate that existing directories contain .git subdirectory before skipping clone
**Rationale:**
- Addresses critical gap: empty or partial clone directories would be skipped
- Requirement 5.2-5.4 now check for valid .git folder
- Prevents false positives where directory exists but isn't a valid repo
**Status:** ✅ Updated Requirement 5

### Exit Code Strategy
**Decision:** Exit 0 if at least one repo succeeds, exit 1 if all fail
**Rationale:**
- Balances resilience (one failure shouldn't fail entire setup) with correctness (total failure is an error)
- Addresses design review criticism about exit 0 violating Unix principles
**Status:** ✅ Updated Requirement 6.5-6.6

### Error Handling Pattern
**Decision:** Use `|| true` pattern for git operations to prevent set -e exit
**Rationale:**
- Script uses `set -e` globally for critical operations (Xcode, Homebrew)
- Git clone failures should not trigger exit
- Explicit about implementation approach (addresses requirement 6.4 ambiguity)
**Status:** ✅ Updated Requirement 6.4

### Logging Format
**Decision:** Stdout for normal messages, stderr for errors, emoji style matching existing script
**Rationale:**
- Consistency with existing new-mac.sh style (🚀, ✅ emojis)
- Standard Unix practice: stdout for output, stderr for errors
- Makes logs machine-parseable
**Status:** ✅ Specified across multiple requirements

### Scope Shift: Fresh Mac Setup Focus
**Decision:** Shift from "idempotent for re-running" to "fresh Mac setup with optional idempotency"
**Rationale:**
- User clarified: "assumption should always be that this script will be run on a fresh and new mac"
- Changes focus from defensive re-run handling to comprehensive initial setup
- Simplifies requirements and implementation
- Idempotency remains for graceful handling of partial runs
**Impact:**
- Simplified idempotency requirements
- Added SSH key generation (not out of scope anymore)
- Added git config setup from template
- Critical vs non-critical error handling distinction
**Status:** ✅ Requirements rewritten with this focus

### SSH Key Generation Addition
**Decision:** Script SHALL generate SSH keys and upload to GitHub
**Rationale:**
- Fresh Mac won't have SSH keys
- Addresses design critic's point about "mandate SSH but know keys might not exist"
- Uses `gh ssh-key add` for automatic upload
- Prompts for GitHub email for key comment
**Status:** ✅ Added as Requirement 1

### Git Configuration from Template
**Decision:** Script SHALL set up .gitconfig from `macos/gitconfig` template with user input
**Rationale:**
- User requirement: "The script SHOULD set up the .gitconfig file per the repo template"
- Prompts for name and email as script input variables
- Preserves template structure (conditional includes, core.sshCommand)
**Status:** ✅ Added as Requirement 2

### User Input Collection Strategy
**Decision:** Collect all user input at the beginning, then proceed unattended
**Rationale:**
- Better UX: user provides info once, then can walk away
- Avoids mid-script prompts that block progress
- Allows validation and re-prompting before heavy operations
**Status:** ✅ Added as Requirement 7

### Single Sudo Prompt
**Decision:** Sudo only asked once at beginning (for Homebrew, already in script)
**Rationale:**
- User requirement: "tools should allow one script to run, ask for sudo once"
- SSH key gen, git config, cloning, tool installation don't need sudo
- Homebrew already handles this
**Status:** ✅ Specified in Requirement 10.6

### Focus on NEW Functionality Only
**Decision:** Requirements focus on what's being ADDED, not duplicating existing script functionality
**Rationale:**
- User clarified: "Go installation, homebrew, and other prerequisites to repo setup are part of the setup process. Look at the install new-mac.sh script for context."
- Existing script already handles: Xcode, Homebrew, PATH setup, Oh-My-Zsh, packages, .vimrc, .zshrc
- NEW functionality: gh/go packages, SSH keys, gitconfig, ~/repos/, cloning, tool installation
**Impact:**
- Simplified requirements to focus on additions
- Removed redundant requirements about prerequisites
- Added clear integration points showing where new code fits
**Status:** ✅ Requirements revised to focus on NEW sections only

### Package Installation Strategy
**Decision:** Add `gh` and `go` to existing brew packages list
**Rationale:**
- Leverages existing package installation mechanism (line 54-63 in new-mac.sh)
- No need for separate installation logic
- Consistent with existing pattern
**Status:** ✅ Specified in Requirement 1

### GitHub Authentication Flow
**Decision:** Use `gh auth login` before SSH key upload
**Rationale:**
- `gh ssh-key add` requires GitHub authentication
- User needs to authenticate once to upload SSH key
- Subsequent git operations use SSH key
**Status:** ✅ Added to Requirement 2.7

### Git Config Template Download
**Decision:** Download gitconfig template via curl from raw GitHub URL
**Rationale:**
- Consistent with existing pattern (script downloads .vimrc and .zshrc via curl)
- Works even if workscripts repo not cloned yet
- Simple text replacement for name/email placeholders
**Status:** ✅ Specified in Requirement 3.5-3.7

### Agentic-Coding Repository Addition
**Decision:** Clone `ArjenSchwarz/agentic-coding` as fourth repository
**Rationale:**
- User requirement: add git@github.com:ArjenSchwarz/agentic-coding.git
- Contains Claude Code skills that should be available
- Non-tool repository (no binary installation needed)
**Status:** ✅ Added to Requirement 5.5

### Claude Code Skills Symlink
**Decision:** Create symlink from `~/.claude/skills` to `~/repos/agentic-coding/claude/skills`
**Rationale:**
- User requirement: "create a symlink to the local user .claude/ directory"
- Makes agentic-coding skills available to Claude Code automatically
- Standard pattern: lrwxr-xr-x user staff ~/.claude/skills -> ~/repos/agentic-coding/claude/skills
- Check if symlink already points to correct location (idempotency)
- Warn if ~/.claude/skills exists but is not a symlink or points elsewhere
**Status:** ✅ Added as new Requirement 6

### Minimize User Input
**Decision:** Reduce prompts to 2 inputs: GitHub email and Git name
**Rationale:**
- User emphasis: "Focus on minimal user input after pulling script from github"
- Use same email for SSH key comment and gitconfig (single prompt)
- Git name is only other required personalization
- Everything else automated or has defaults
**Impact:** Updated Requirement 8 to specify 2 prompts only
**Status:** ✅ Updated Requirement 8.2, 8.7

---

## Design Phase Updates (2026-03-10)

### Embed Gitconfig Template
**Decision:** Embed gitconfig template in script using heredoc instead of downloading from GitHub
**Rationale:**
- User decision: "Embed in script"
- Removes external network dependency
- Eliminates template integrity/security concerns
- Simpler implementation (no curl, no sed escaping issues)
- Template is stable and unlikely to change frequently
**Impact:** Component 4 redesigned with embedded heredoc template
**Status:** ✅ Updated in design document

### Comprehensive Logging to ~/SETUP.log
**Decision:** Log all operations (stdout and stderr) to ~/SETUP.log for debugging and audit
**Rationale:**
- User decision: "log failures meaningfully in ~/SETUP.log"
- Provides detailed troubleshooting information
- Creates audit trail of setup operations
- All commands use `| tee -a ~/SETUP.log` to log while displaying output
- Error messages reference log file for details
**Impact:** All components updated with logging
**Status:** ✅ Updated across all components

### Continue on Error with Better Messaging
**Decision:** Keep "continue on error" approach for non-critical operations, improve messaging
**Rationale:**
- User decision: "Keep continue on error"
- Non-critical failures (repos, tools) log detailed errors but don't stop script
- Summary message differentiates "Setup complete" vs "Setup completed with issues"
- Users check ~/SETUP.log for full diagnostics
**Impact:** Component 9 updated with conditional success message
**Status:** ✅ Updated in design document

### Dependency Verification Upfront
**Decision:** Check for gh, go, git before starting new sections
**Rationale:**
- Addresses design review finding: "Dependencies not verified upfront"
- Fails fast if prerequisites missing (before user input)
- Clearer error message than cryptic mid-script "command not found"
**Impact:** Component 2 adds dependency verification loop
**Status:** ✅ Added to Component 2

### SSH Key Deduplication
**Decision:** Check if SSH key already uploaded to GitHub before attempting gh ssh-key add
**Rationale:**
- Addresses design review finding: "might upload duplicate keys"
- Compare fingerprints using `ssh-keygen -lf` and `gh ssh-key list`
- Avoids API errors on re-run
- Improves idempotency
**Impact:** Component 3 adds fingerprint comparison logic
**Status:** ✅ Added to Component 3

### Subshell Directory Safety
**Decision:** Use subshells `(cd dir && command)` instead of `cd dir; command; cd -`
**Rationale:**
- Addresses design review finding: "cd without error handling"
- Subshell prevents directory state corruption if cd fails
- Automatic cleanup when subshell exits
- No need for manual `cd -` return
**Impact:** Component 8 redesigned with subshells
**Status:** ✅ Updated in Component 8

### PATH Verification and Warning
**Decision:** Verify ~/go/bin in PATH after tool installation, warn if missing
**Rationale:**
- Addresses design review finding: "PATH requirements undefined"
- Go tools install to ~/go/bin by default
- Script can't modify PATH (affects parent shell only)
- Warn user to add to shell config if not present
- Verify tools are executable after install
**Impact:** Component 8 adds PATH check and tool verification
**Status:** ✅ Added to Component 8

### No Input Validation
**Decision:** Keep minimal non-empty validation only, no email/name format checks
**Rationale:**
- User decision: "Minimal interaction"
- Prioritizes speed over correctness
- User accepts risk of invalid email/name
- Git will complain on first commit if email invalid
- Can be fixed post-setup with `git config --global`
**Impact:** No changes needed (existing design already minimal)
**Status:** ✅ Decision documented

### User-Specific Repository List
**Decision:** Keep hardcoded repository list as-is (not general-purpose)
**Rationale:**
- User decision: "Leave as is - it is meant for specifics"
- This is a personal setup script, not a general framework
- Generalization considered for future iteration
- Clear in design that this is user-specific
**Impact:** Design document updated to emphasize user-specific nature
**Status:** ✅ Updated in design principles
