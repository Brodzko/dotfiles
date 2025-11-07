# ~/.zshrc

source "$ZDOTDIR/.zsh_secrets.zsh"

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # Ensure homebrew bin takes precedence over /usr/local/bin
  export PATH="/opt/homebrew/bin:${PATH#/opt/homebrew/bin:}"
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

efdev() {
  DEV_PATH="$1" tmuxinator start ef-dev
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

zinit ice as"program" pick"bin/git-fuzzy"
zinit light bigH/git-fuzzy

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

# fnm - Fast Node Manager
eval "$(fnm env --use-on-cd)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

export COREPACK_ENABLE_AUTO_PIN=0
# pnpm end

alias pnx="pnpm nx"

custom_ls() {
  eza --icons --color=always --git-ignore "$@"
}

alias ls="custom_ls"

lst() {
  custom_ls --tree --level="$@"
}

alias ..="cd .."
alias ...="cd ../.."

export LSCOLORS="gxBxhxDxfxhxhxhxhxcxcx"

# General aliases
alias home="cd $HOME"
alias clr="clear"
alias q="source '$HOME/zsh/.zshrc'"

export FZF_ALT_C_COMMAND='fd --type d --follow --hidden --exclude node_modules --exclude .git --exclude .Trash --exclude .cache'

source "$ZDOTDIR/git/git.zsh"
source "$ZDOTDIR/gitlab/gitlab.zsh"

source "$ZDOTDIR/jira/client.zsh"
source "$ZDOTDIR/elis_be.zsh"

# Syntax higlighting, needs to be at the end of file
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Added by Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

export DOCKER_HOST="unix://$HOME/.colima/docker.sock"

source "$ZDOTDIR/brew.zsh"

