alias ll='ls -laH'
alias tf='terraform'
alias tfaaa='terraform apply --auto-approve'
alias tfddd='terraform destroy --auto-approve'
alias gl='git log --oneline --graph'
alias ggc='vim ~/.gitconfig'
alias c='clear'
alias py='python3'
alias brup="brew update; brew upgrade; brew upgrade --cask --greedy; brew uninstall microsoft-auto-update; brew cleanup -s"
alias guck='git remote get-url origin | read origin && git rev-parse --show-toplevel | read repo && cd "$repo/.." && rm -rf "$repo" && git clone $origin && cd $repo && repo="" && origin=""'
alias gitprune='git remote prune origin && git branch -vv | grep '\''origin/.*: gone]'\'' | awk '\''{print $1}'\'' | xargs git branch -D'
alias ssmsesh='aws ssm start-session --region ap-southeast-2 --target'
alias zshconfig="code ~/.zshrc"
alias dockernuke='docker stop $(docker ps -aq); docker rm $(docker ps -aq); docker rmi $(docker images -q); docker-buildx prune -af'
alias dockerclear='docker stop $(docker ps -aq); docker rm $(docker ps -aq); docker rmi $(docker images -q)'
alias ohmyzsh="code ~/.oh-my-zsh"
alias removetheme="cp ~/.zshrc ~/.zshrc.bak; sed -i '' 's/ \"$RANDOM_THEME\"//g' ~/.zshrc; source ~/.zshrc"
alias gc='gcloud'
alias cat='bat'
alias chrdebug="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222"