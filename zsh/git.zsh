export ZSHRC_DIR="${0:A:h}"

source "$ZSHRC_DIR/chalk.zsh"
source "$ZSHRC_DIR/fancy_symbols.zsh"
source "$ZSHRC_DIR/utils.zsh"
source "$ZSHRC_DIR/preview_utils.zsh"

# Git aliases
#############
# alias gst="git status"
alias gpl="git pull"
alias gps="git push"
alias gpsf="git push --force-with-lease"
alias gf="git fetch"

alias gc="git commit"
alias gca="git add . && git commit"
alias gcam="git commit --amend --no-edit"
alias gcaam="git add . && git commit --amend --no-edit"

# Interactive branch switch
gsw() {
  local branch
  # git fetch --all --prune
  branch=$(git branch -a | grep -v HEAD | sed 's/^..//' | fzf)
  [[ -z "$branch" ]] && return

  if [[ "$branch" == remotes/* ]]; then
    local remote_branch=${branch#remotes/}
    git switch --track "$remote_branch"
  else
    git switch "$branch"
  fi
}

gsc() {
  if [ -n "$1" ]; then
    echo "Checking out new branch from develop..."
    git checkout develop
    git pull
    git switch -c "$1"
  else
    echo "Error: You need to specify branch name!"
  fi
}

gscm() {
  if [ -n "$1" ]; then
    echo "Checking out new branch from master..."
    git checkout master
    git pull
    git switch -c "$1"
  else
    echo "Error: You need to specify branch name!"
  fi
}

alias gprstale="git branch -v | grep '\[gone\]' | awk '{print \$1}' | xargs -r git branch -D"
alias gprstaleman="git branch -v | fzf -m --reverse --info=inline | awk '{print \$1}' | xargs -r git branch -D"

# Interactive stage
alias gad="git status --porcelain | rg '^(.\?|.M|.D|.R|.U)' | fzf -m --reverse --info=inline --preview 'git diff --color=always --wrap -- \$(echo {} | awk '\''{print substr(\$0, 4)}'\'') | delta --color-only' | awk '{print substr(\$0, 4)}' | xargs -r git add && git status -u"
alias gadp="git status --porcelain | rg '^(.\?|.M|.D|.R|.U)' | fzf -m --preview 'git diff --color=always --wrap -- \$(echo {} | awk '\''{print substr(\$0, 4)}'\'') | delta --color-only' | awk '{print substr(\$0, 4)}' | xargs -r -o git add -p"

# Interactive unstage
alias grest="git diff --name-only --cached | fzf -0 -m --preview 'git diff --staged --color=always {-1} | delta --color-only' | xargs -r git reset -q HEAD -- && git status --u"

# Logs
alias glog="git log --pretty=format:'%C(auto)%h%C(reset) %C(auto)%d%C(reset) %s %C(cyan)[%an]%C(reset) %C(dim white)(%cr)%C(reset)' --abbrev-commit --date=relative"
alias glogg="git log --graph --pretty=format:'%C(auto)%h%C(reset) %C(auto)%d%C(reset) %s %C(cyan)[%an]%C(reset) %C(dim white)(%cr)%C(reset)' --abbrev-commit --date=relative"

# V2 - interactive status
gst() {
  git status --porcelain |
    fzf --ansi --no-sort \
      --height=80% --layout=reverse \
      --border --header "Uncommited Changes (Staged: X, Unstaged: Y)" \
      --preview \
      'echo {}'
}
