#!/usr/bin/env zsh

source "$ZDOTDIR/chalk.zsh"
source "$ZDOTDIR/fancy_symbols.zsh"
source "$ZDOTDIR/utils.zsh"

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

# Logs
alias glog="git log --pretty=format:'%C(auto)%h%C(reset) %C(auto)%d%C(reset) %s %C(cyan)[%an]%C(reset) %C(dim white)(%cr)%C(reset)' --abbrev-commit --date=relative"
alias glogg="git log --graph --pretty=format:'%C(auto)%h%C(reset) %C(auto)%d%C(reset) %s %C(cyan)[%an]%C(reset) %C(dim white)(%cr)%C(reset)' --abbrev-commit --date=relative"

get_status_color() {
  # Unstaged
  if [[ "$1" == "??" ]]; then
    echo "red"
  # Merge conflicts
  elif [[ "$1" =~ "^(U.|.U)" ]]; then
    echo "bg_red black"
  # Renames
  elif [[ "$1" =~ "^(R.|.R)" ]]; then
    echo "magenta"
  # Unstaged only
  elif [[ "$1" =~ "^ ." ]]; then
    echo "red"
  # Staged only
  elif [[ "$1" =~ "^. " ]]; then
    echo "green"
  # Changes in both
  elif [[ "$1" =~ "^.." ]]; then
    echo "yellow"
  else
    echo "white"
  fi
}

# Parse information out of a git status line
parse_git_status_line() {
  local line="$1"
  local full_status staged unstaged rest pathspec oldpath

  line="${line//$'\n'/}"

  [[ -z "$line" ]] && return

  full_status="${line:0:2}"
  staged="${line:0:1}"
  unstaged="${line:1:1}"
  rest="${line:3}"
  rest="${rest#"${rest%%[![:space:]]*}"}" # trim leading whitespace

  oldpath=""
  pathspec="$rest"

  if [[ "$rest" == \"*\" ]]; then
    rest="${rest%\"}"
    rest="${rest#\"}"
    if [[ "$rest" == *' -> '* ]]; then
      oldpath="${rest%% -> *}"
      pathspec="${rest##* -> }"
    else
      pathspec="$rest"
    fi
  else
    if [[ "$rest" == *' -> '* ]]; then
      oldpath="${rest%% -> *}"
      pathspec="${rest##* -> }"
    fi
  fi

  print -r -- "${full_status}"$'\t'"${staged}"$'\t'"${unstaged}"$'\t'"${rest}"$'\t'"${pathspec}"$'\t'"${oldpath}"

}

enhanced_git_status() {
  local status_lines=()
  local sep=$'\x1f'  # Use a safe delimiter
  local line output pathspec full_status

  while IFS= read -r line; do
    output="$(parse_git_status_line "$line")"
    IFS=$'\t' read -r full_status _ _ _ pathspec _ <<<"$output"
    status_lines+=("${pathspec}${sep}${line}")
  done < <(git status --porcelain)

  for entry in "${(on)status_lines[@]}"; do
    pathspec="${entry%%$sep*}"
    line="${entry#*$sep}"
    full_status=$(parse_git_status_line "$line" | awk -F'\t' '{ print $1 }')
    echo "$(chalk $(get_status_color "$full_status") bold "$line")"
  done
}

print_preview() {
  local diff_kind=$1
  local input_line=$2

  IFS=$'\t' read -r full_status staged unstaged rest pathspec oldpath <<< "$(parse_git_status_line "$input_line")"

  local diff_status=$(if [[ "$diff_kind" == 'staged' ]]; then echo "$staged"; else echo "$unstaged"; fi)
  local -a params=()

  if [[ "$diff_kind" == "staged" ]]; then
    params+=(--cached)
  elif [[ "$diff_kind" == "both" ]]; then
    params+=(HEAD)
  fi

  if [[ "$diff_status" == "R" || "$diff_status" == "T" || "$diff_status" == "C" ]]; then
    params+=(-M)
  fi

  if [[ $diff_status == "?" ]]; then
    echo $(chalk cyan bold "head -n 50 \"$pathspec\"")
    echo ""
    head -n 50 "$pathspec" | bat --color=always 
  elif [[ "$diff_status" =~ ^(R|T|C|M|A|U|D| ) ]]; then
    echo $(chalk cyan bold "git diff ${params[@]} -- $pathspec")
    echo ""
    git diff ${params[@]} -- $pathspec | delta --width=$FZF_PREVIEW_COLUMNS
  else
    echo $(chalk red bold "Unhandled case!")
  fi
}

# V2 - interactive status
gst() {
  enhanced_git_status |
    fzf --ansi --no-sort \
      --height=100% --layout=reverse \
      --color="hl:bright-white,hl+:bright-white" \
      --disabled --no-input \
      --multi \
      --preview-window=right,70%,wrap \
      --preview \
      'source $ZDOTDIR/git/git.zsh; print_preview unstaged {}' \
      --bind "1:change-preview(source $ZDOTDIR/git/git.zsh; print_preview staged {})" \
      --bind "2:change-preview(source $ZDOTDIR/git/git.zsh; print_preview unstaged {})" \
      --bind "3:change-preview(source $ZDOTDIR/git/git.zsh; print_preview both {})" \
      --bind "0:execute(source $ZDOTDIR/git/git.zsh; print_preview staged {})" \
      --bind "9:execute(source $ZDOTDIR/git/git.zsh; print_preview unstaged {})" \
      --bind "8:execute(source $ZDOTDIR/git/git.zsh; print_preview both {})" \
      --bind "s:execute-silent(source $ZDOTDIR/git/git.zsh; stage_file {})+reload-sync(source $ZDOTDIR/git/git.zsh; enhanced_git_status)" \
      --bind "u:execute-silent(source $ZDOTDIR/git/git.zsh; unstage_file {})+reload-sync(source $ZDOTDIR/git/git.zsh; enhanced_git_status)" \
      --bind "S:execute-silent()+reload(enhanced_git_status)" \
      --bind "U:execute-silent()+reload(enhanced_git_status)" \
      --bind "alt-s:execute(git add -p)+reload-sync(source $ZDOTDIR/git/git.zsh; enhanced_git_status)" \
      --bind "alt-u:execute(git restore -p)+reload-sync(source $ZDOTDIR/git/git.zsh; enhanced_git_status)" \
      --bind "ctrl-alt-r:execute-silent()+reload(enhanced_git_status)" \
      --bind "ctrl-alt-R:execute-silent()+reload(enhanced_git_status)" \
      "$@"
}

gad() {
  gst --bind "ctrl-a:become(echo Hello)"
}
