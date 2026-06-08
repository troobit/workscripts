# Shell aliases and small functions sourced from ~/.aliases.zsh.
# Repo-managed: edits here should be committed and pushed; new-mac.sh re-downloads from main.

# --- Filesystem / shell basics ---
alias ll='ls -laH'
alias c='clear'
alias cat='bat'              # `bat` = syntax-highlighted `cat`

# --- Python ---
alias py='python3'

# --- Editors / configs ---
alias ggc='vim ~/.gitconfig'
alias zshconfig="code ~/.zshrc"
alias ohmyzsh="code ~/.oh-my-zsh"
# Strip the oh-my-zsh random theme line from .zshrc, back up first, then re-source.
alias removetheme="cp ~/.zshrc ~/.zshrc.bak; sed -i '' 's/ \"$RANDOM_THEME\"//g' ~/.zshrc; source ~/.zshrc"

# --- Terraform ---
alias tf='terraform'
alias tfaaa='terraform apply --auto-approve'
alias tfddd='terraform destroy --auto-approve'

# --- Git ---
alias gl='git log --oneline --graph'
# Nuke the current repo working dir and re-clone fresh from origin (destructive — uncommitted work is lost).
alias guck='git remote get-url origin | read origin && git rev-parse --show-toplevel | read repo && cd "$repo/.." && rm -rf "$repo" && git clone $origin && cd $repo && repo="" && origin=""'
# Prune stale remote refs and delete local branches whose upstream is gone.
alias gitprune='git remote prune origin && git branch -vv | grep '\''origin/.*: gone]'\'' | awk '\''{print $1}'\'' | xargs git branch -D'

# --- Cloud ---
alias gc='gcloud'
alias ssmsesh='aws ssm start-session --region ap-southeast-2 --target'   # pass an instance id

# --- Homebrew ---
# Update + upgrade everything (incl. casks, --greedy for auto-updaters), remove MS AutoUpdate, vacuum old versions.
alias brup="brew update; brew upgrade; brew upgrade --cask --greedy; brew uninstall microsoft-auto-update; brew cleanup -s"

# --- Containers (Podman, transparently aliased as docker) ---
alias docker='podman'
alias docker-compose='podman-compose'
# Full wipe: stop+rm all containers, rm all images, prune everything.
alias dockernuke='podman stop $(podman ps -aq) 2>/dev/null; podman rm $(podman ps -aq) 2>/dev/null; podman rmi $(podman images -q) 2>/dev/null; podman system prune -af'
# Same wipe minus the system prune.
alias dockerclear='podman stop $(podman ps -aq) 2>/dev/null; podman rm $(podman ps -aq) 2>/dev/null; podman rmi $(podman images -q) 2>/dev/null'

# --- Browser ---
# Launch Chrome with the DevTools Protocol exposed on :9222 (for Puppeteer/Playwright/manual remote debugging).
alias chrdebug="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222"

# --- Markdown → PDF ---
# Convert a Markdown file to PDF for printing (e.g. `md2pdf docs/new-mac-guide.md`).
# Uses weasyprint (already installed via `brew install pango weasyprint` for invoicer) and pulls
# python-markdown into a transient venv via `uv run --with`. Nothing is installed globally.
# Usage:
#   md2pdf input.md              # writes input.pdf next to input.md
#   md2pdf input.md output.pdf   # explicit output path
# Note: DYLD_FALLBACK_LIBRARY_PATH points uv's bundled Python at Homebrew's Pango libs;
# without it weasyprint fails to load libgobject.
md2pdf() {
  if [[ -z "$1" ]]; then
    echo "usage: md2pdf <input.md> [output.pdf]" >&2
    return 1
  fi
  local in="$1"
  local out="${2:-${in%.md}.pdf}"
  DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib uv run --with markdown --with weasyprint \
    python -c 'import sys,markdown,weasyprint;weasyprint.HTML(string=markdown.markdown(open(sys.argv[1]).read(),extensions=["fenced_code","tables","toc"])).write_pdf(sys.argv[2])' \
    "$in" "$out" \
    && echo "wrote $out"
}
