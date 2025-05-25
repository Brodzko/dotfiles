# ~/.zshrc

ZSHRC_DIR="${0:A:h}"

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

function update_tab_title() {
  # Get foreground command (from $! or $jobs may not be reliable here)
  # local cmd="$(ps -o comm= -p $(ps -o ppid= -p $$) 2>/dev/null | head -n1)"

  # Get current directory
  local dir="$(basename "$PWD")"

  # Get Git branch if in repo
  local branch=""
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
    branch="($(git rev-parse --abbrev-ref HEAD 2>/dev/null))"
  fi

  # Compose title
  local title=""
  # [[ -n "$cmd" ]] && title+="$cmd "
  title+="$dir"
  [[ -n "$branch" ]] && title+=" $branch"

  # Set tab title
  echo -ne "\033]1;$title\007"
}

# Call before every prompt
preexec_functions+=(update_tab_title)

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# History
HISTSIZE=5000
SAVEHIST=$HISTSIZE
HISTFILE=~/.zsh_history
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light MichaelAquilina/zsh-you-should-use

# Add in snippets
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found
zinit snippet OMZP::nvm

# Initialize completion
autoload -U compinit
compinit

zinit cdreplay -q

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

eval "$(fzf --zsh)"
eval "$(starship init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# pnpm
export PNPM_HOME="/Users/martin.brodziansky@rossum.ai/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

export COREPACK_ENABLE_AUTO_PIN=0
# pnpm end

alias pnx="pnpm nx"
alias ls="ls --color"

export LSCOLORS="gxBxhxDxfxhxhxhxhxcxcx"

# General aliases
alias home="cd $HOME"
alias clr="clear"

# Git aliases
#############
alias gst="git status"
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
  if [ -n "$1" ];
  then
    echo "Checking out new branch from develop..."
    git checkout develop
    git pull
    git switch -c "$1"
  else
    echo "Error: You need to specify branch name!"
  fi
}

gscm() {
  if [ -n "$1" ];
  then
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
alias gad="git status --porcelain | rg '^(.\?|.M|.D|.R|.U)' | fzf -m --reverse --info=inline --preview 'git diff --color=always -- \$(echo {} | awk '\''{print substr(\$0, 4)}'\'') | delta --color-only' | awk '{print substr(\$0, 4)}' | xargs -r git add && git status -u"
alias gadp="git status --porcelain | rg '^(.\?|.M|.D|.R|.U)' | fzf -m --preview 'git diff --color=always -- \$(echo {} | awk '\''{print substr(\$0, 4)}'\'') | delta --color-only' | awk '{print substr(\$0, 4)}' | xargs -r -o git add -p"

# Interactive unstage
alias grest="git diff --name-only --cached | fzf -0 -m --preview 'git diff --staged --color=always {-1} | delta --color-only' | xargs -r git reset -q HEAD -- && git status --u"

# Logs
alias glog="git log --pretty=format:'%C(auto)%h%C(reset) %C(auto)%d%C(reset) %s %C(cyan)[%an]%C(reset) %C(dim white)(%cr)%C(reset)' --abbrev-commit --date=relative"
alias glogg="git log --graph --pretty=format:'%C(auto)%h%C(reset) %C(auto)%d%C(reset) %s %C(cyan)[%an]%C(reset) %C(dim white)(%cr)%C(reset)' --abbrev-commit --date=relative"

source "$ZSHRC_DIR/gitlab.zsh"

source "$ZSHRC_DIR/chalk.zsh"

chalk bold italic bright_red bg_green dim "Hello world"

# Syntax higlighting, needs to be at the end of file
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
