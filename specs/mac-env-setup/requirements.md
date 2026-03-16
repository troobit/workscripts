# Requirements — mac-env-setup

## Introduction

Enhance the `macos/new-mac.sh` setup script and supporting shell configuration files to provide a complete, automated macOS environment. This includes: configuring the macOS Dock with a curated set of pinned applications (removing all defaults), installing Podman as the container runtime with docker-compatible aliases, providing a reference compose file for local development, and adding new applications (Brave Browser, WhatsApp) to the Homebrew install list. All changes must be idempotent and safe to re-run on an already-configured Mac.

**Tool dependency:** Dock manipulation uses `dockutil` (installed via Homebrew).
**Execution order:** Homebrew packages → Shell config deployment → Dock configuration.
**Error strategy:** All new sections are non-critical and use `|| true` guards to avoid `set -e` termination.

---

### 1. Dock Configuration — App Pinning

**User Story:** As a developer setting up a new Mac, I want the Dock to contain only my chosen apps, so that I have a clean, distraction-free workspace from the start.

**Acceptance Criteria:**

1. <a name="1.1"></a>The `default_packages` array SHALL include `dockutil` as a prerequisite for Dock manipulation
2. <a name="1.2"></a>The script SHALL use `dockutil --remove all --no-restart` to remove all existing persistent apps from the macOS Dock (Finder is preserved automatically by macOS). The `--no-restart` flag is supported in dockutil v3.1.3 and batches changes before a single Dock restart
3. <a name="1.3"></a>The script SHALL add the following apps to the Dock in this order: Brave Browser, WhatsApp, iTerm2, Calendar
4. <a name="1.4"></a>The script SHALL verify each app exists in `/Applications/`, `/System/Applications/`, or `/System/Library/CoreServices/` before adding it to the Dock, and log a warning if the app is not found
5. <a name="1.5"></a>The script SHALL restart the Dock process (`killall Dock`) after applying all changes
6. <a name="1.6"></a>WHEN the script is re-run on an already-configured Mac, THEN it SHALL produce the same Dock state without errors

---

### 2. Dock Configuration — Disable Recent Apps

**User Story:** As a developer, I want the Dock to not show recent applications, so that my Dock stays clean and predictable.

**Acceptance Criteria:**

1. <a name="2.1"></a>The script SHALL set `show-recents` to `false` in the `com.apple.dock` domain via `defaults write`
2. <a name="2.2"></a>WHEN the Dock is restarted after this change, THEN the "Show recent applications in Dock" section SHALL not be visible

---

### 3. Homebrew Package List Updates

**User Story:** As a developer setting up a new Mac, I want Brave Browser and WhatsApp installed automatically, so that I don't need to install them manually after setup.

**Acceptance Criteria:**

1. <a name="3.1"></a>The `default_packages` array in `new-mac.sh` SHALL include `brave-browser`
2. <a name="3.2"></a>The `default_packages` array in `new-mac.sh` SHALL include `whatsapp`
3. <a name="3.3"></a>The `default_packages` array in `new-mac.sh` SHALL include `dockutil`
4. <a name="3.4"></a>The existing Homebrew install flow SHALL install these packages alongside all other defaults without additional user interaction

---

### 4. Podman Compose File

**User Story:** As a developer, I want a reference docker-compose.yml file for local container-based development, so that I can spin up a database and app container with proper isolation using `docker-compose up`.

**Acceptance Criteria:**

1. <a name="4.1"></a>A `macos/docker-compose.yml` file SHALL be created in the repository
2. <a name="4.2"></a>The compose file SHALL define a PostgreSQL service with a named volume for data persistence
3. <a name="4.3"></a>The compose file SHALL define a placeholder app service on the same network as the database
4. <a name="4.4"></a>The compose file SHALL use volume mounts to a project-specific subdirectory (e.g., `~/repos/<project>/`) rather than mounting `~/repos` directly
5. <a name="4.5"></a>The services SHALL be on a shared network with DNS enabled for container name resolution
6. <a name="4.6"></a>The compose file SHALL use environment variables for configurable values (database credentials, ports)
7. <a name="4.7"></a>The setup script SHALL NOT run `podman machine init`, `podman machine start`, or any containers — Podman is installed via Homebrew only

---

### 5. Docker-Compatible Aliases

**User Story:** As a developer transitioning from Docker to Podman, I want `docker` and `docker-compose` commands to transparently invoke Podman, so that existing workflows and docker-compose.yml files work without modification.

**Acceptance Criteria:**

1. <a name="5.1"></a>The `aliases.zsh` file SHALL define `alias docker='podman'`
2. <a name="5.2"></a>The `aliases.zsh` file SHALL define `alias docker-compose='podman-compose'`
3. <a name="5.3"></a>The existing `dockernuke` alias SHALL be updated to use `podman` commands and handle the case where no containers or images exist (avoid empty-argument errors)
4. <a name="5.4"></a>The existing `dockerclear` alias SHALL be updated to use `podman` commands and handle the case where no containers or images exist
5. <a name="5.5"></a>The aliases SHALL support running local `docker-compose.yml` files via `docker-compose up` for common Compose features (note: `podman-compose` has known incompatibilities with some advanced Compose features)

---

### 6. Shell Configuration Deployment

**User Story:** As a developer, I want my shell aliases deployed automatically, so that my terminal environment is fully configured after setup.

**Acceptance Criteria:**

1. <a name="6.1"></a>The setup script SHALL download `aliases.zsh` from the repository to `~/.aliases.zsh`
2. <a name="6.2"></a>The `path.zsh` file SHALL be removed from the repository — pnpm PATH is handled by `brew install pnpm`, NVM is not installed by the script, and Homebrew PATH is already handled by `eval "$(/opt/homebrew/bin/brew shellenv)"`
3. <a name="6.3"></a>The `zshrc` template SHALL include a `source ~/.aliases.zsh` line (with existence check)
4. <a name="6.4"></a>WHEN the script is re-run, THEN it SHALL overwrite the aliases file with the latest version (repo-managed, not user-edited)
5. <a name="6.5"></a>IF `aliases.zsh` cannot be downloaded, THEN the script SHALL log a warning and continue (non-critical)

---

### 7. Idempotency and Error Handling

**User Story:** As a developer, I want the setup script to be safe to re-run at any time, so that I can use it to repair or update my environment without side effects.

**Acceptance Criteria:**

1. <a name="7.1"></a>Every new section added to `new-mac.sh` SHALL check for existing state before making changes
2. <a name="7.2"></a>WHEN a non-critical operation fails (Dock config, shell config download), THEN the script SHALL use `|| true` or subshell guards to log the error and continue despite `set -e`
3. <a name="7.3"></a>All new operations SHALL be logged to `~/SETUP.log` consistent with the existing logging pattern
4. <a name="7.4"></a>The Dock configuration and shell config sections SHALL be placed after the `exec > >(tee ...)` logging redirect (after line 82 in the current script) so all output is captured
