# You can put files here to add functionality separated per file, which
# will be ignored by git.
# Files on the custom/ directory will be automatically loaded by the init
# script, in alphabetical order.

alias tf='terraform'
alias tfaaa='terraform apply --auto-approve'
alias tfddd='terraform destroy --auto-approve'
alias gl='git log --oneline --graph'
alias ggc='vim ~/.gitconfig'
alias c='clear'
alias py='python3'
alias brup="brew update; brew upgrade; brew upgrade --cask --greedy; brew cleanup -s"
alias guck='git remote get-url origin | read origin && git rev-parse --show-toplevel | read repo && cd "$repo/.." && rm -rf "$repo" && git clone $origin && cd $repo && repo="" && origin=""'
alias gitprune='git remote prune origin && git branch -vv | grep '\''origin/.*: gone]'\'' | awk '\''{print $1}'\'' | xargs git branch -D'
alias ssmsesh='aws ssm start-session --region ap-southeast-2 --target'
alias zshconfig="code ~/.zshrc"
alias ohmyzsh="code ~/.oh-my-zsh"
alias c='clear'

export LSCOLORS='ExGxDxDxCxDxDxFxFxexEx'
#Plugin Options
# autosuggestions
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50
# export ARCHFLAGS="-arch x86_64"
export AWS_PAGER=""
