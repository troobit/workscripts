# You can put files here to add functionality separated per file, which
# will be ignored by git.
# Files on the custom/ directory will be automatically loaded by the init
# script, in alphabetical order.


alias tf='terraform'
alias gl='git log --oneline --graph'
alias ggc='vim ~/.gitconfig'
alias c='clear'

alias tfsudo='export TF_TOKEN_app_terraform_io=""'
alias tfuser='export TF_TOKEN_app_terraform_io=""'
alias tfreset='tfsudo && tf init && tfuser'

#Plugin Options
# autosuggestions
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50
