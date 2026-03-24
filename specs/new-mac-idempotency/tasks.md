---
references:
    - specs/new-mac-idempotency/smolspec.md
---
# new-mac.sh Idempotency Tasks

## Completed

- [x] 1. Remove invalid packages and restructure package configuration <!-- id:krasqml -->
  - Removed codelayer (invalid Homebrew package) and tailscale-app (invalid cask name)
  - Added python to packages_formulae; moved mas from home_packages into packages_formulae
  - Merged default_packages and home_packages into two typed arrays: packages_formulae and packages_casks
  - Placed single PACKAGE CONFIGURATION block at top of script (lines 6-27), before interactive phase
  - Stream: 1

- [x] 2. Separate brew install into typed --formula and --cask calls <!-- id:krasqmm -->
  - Replaced single brew install with two calls: brew install --formula for packages_formulae and brew install --cask for packages_casks
  - Each call has its own warning message identifying which group failed
  - Prevents a cask failure from aborting formula installation and vice versa
  - Stream: 1

- [x] 3. Add python3 Homebrew PATH preference to .zshrc <!-- id:krasqmn -->
  - Added idempotent guard: checks if brew --prefix python already in .zshrc before appending
  - Appends export PATH=$(brew --prefix python)/bin:$PATH to ensure Homebrew python3 takes precedence over macOS system Python
  - Stream: 1

## Implementation

- [x] 4. Audit non-standard package names for Homebrew validity <!-- id:krasqmo -->
  - Run brew info --cask or brew info --formula for: logi-options+, gcloud-cli, lychee, anydesk
  - Remove or replace any that are not valid Homebrew names
  - Update packages_formulae and packages_casks arrays in the PACKAGE CONFIGURATION block (lines 6-27 of new-mac.sh)
  - Stream: 1

- [x] 5. Implement install_packages resilient helper function <!-- id:krasqmp -->
  - Add install_packages() bash function before the BREW PACKAGE INSTALL section
  - Signature: install_packages <flag> <pkg...> where flag is --formula or --cask
  - Attempt batch install first for speed; on failure retry each package individually
  - Append failed package names to global FAILED_PACKAGES array
  - Pattern mirrors clone_repo helper (lines 475-492 of new-mac.sh)
  - Blocked-by: krasqmo (Audit non-standard package names for Homebrew validity)
  - Stream: 1

- [x] 6. Replace direct brew install calls with install_packages helper <!-- id:krasqmq -->
  - Replace brew install --formula ... || echo with: install_packages --formula "${packages_formulae[@]}"
  - Replace brew install --cask ... || echo with: install_packages --cask "${packages_casks[@]}"
  - Remove the now-redundant || echo fallbacks — the helper handles per-package errors internally
  - Blocked-by: krasqmp (Implement install_packages resilient helper function)
  - Stream: 1

- [x] 7. Add FAILED_PACKAGES summary to Summary section <!-- id:krasqmr -->
  - Initialise FAILED_PACKAGES=() array at start of unattended phase alongside REPOS_CLONED and TOOLS_INSTALLED
  - In the Summary section, print list of failed package names if non-empty
  - Include a note to run brew info <name> to diagnose and re-run the script
  - Format consistently with existing REPOS_CLONED/TOOLS_INSTALLED summary output
  - Blocked-by: krasqmp (Implement install_packages resilient helper function)
  - Stream: 1
