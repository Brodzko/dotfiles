#!/usr/bin/env zsh

source "$ZDOTDIR/chalk.zsh"
source "$ZDOTDIR/fancy_symbols.zsh"
source "$ZDOTDIR/utils.zsh"

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
    local cmd="git diff "${params[@]}" -- $pathspec"
    echo $(chalk cyan bold "$cmd")
    echo ""
    git diff ${params[@]} -- "$pathspec" | delta --width=$FZF_PREVIEW_COLUMNS
  else
    echo $(chalk red bold "Unhandled case!")
  fi
}

stage_file() {
  IFS=$'\t' read -r full_status staged unstaged rest pathspec oldpath <<< "$(parse_git_status_line "$1")"
  if [[ -z "$pathspec" ]]; then
    echo "No path specified"
    return
  fi

  git add "$pathspec"
}

unstage_file() {
  IFS=$'\t' read -r full_status staged unstaged rest pathspec oldpath <<< "$(parse_git_status_line "$1")"
  if [[ -z "$pathspec" ]]; then
    echo "No path specified"
    return
  fi

  git restore --staged "$pathspec"
}

stage_all() {
  git add .
}

unstage_all() {
  git restore --staged .
}

patch_stage_file() {
  IFS=$'\t' read -r full_status staged unstaged rest pathspec oldpath <<< "$(parse_git_status_line "$1")"
  if [[ -z "$pathspec" ]]; then
    echo "No path specified"
    return
  fi

  if [[ $unstaged == "?" ]]; then
    echo "Cannot stage untracked file"
    return
  fi

  git add -p "$pathspec"
}

patch_unstage_file() {
  IFS=$'\t' read -r full_status staged unstaged rest pathspec oldpath <<< "$(parse_git_status_line "$1")"
  if [[ -z "$pathspec" ]]; then
    echo "No path specified"
    return
  fi

  if [[ $staged == "?" ]]; then
    echo "Cannot unstage untracked file"
    return
  fi

  git restore --staged -p "$pathspec"
}

reset_file() {
  IFS=$'\t' read -r full_status staged unstaged rest pathspec oldpath <<< "$(parse_git_status_line "$1")"
  if [[ -z "$pathspec" ]]; then
    echo "No path specified"
    return
  fi

  if [[ $staged == "?" ]]; then
    git clean -f "$pathspec"
  fi

  git checkout -- "$pathspec"
}

# V2 - interactive status
gst() {
  enhanced_git_status |
    fzf --ansi --no-sort \
      --height=100% --layout=reverse \
      --color="hl:bright-white,hl+:bright-white" \
      --disabled --no-input \
      --preview-window=right,70%,wrap \
      --preview \
      'source $ZDOTDIR/git/git.zsh; print_preview unstaged {}' \
      --bind "1:change-preview(source $ZDOTDIR/git/git.zsh; print_preview staged {})" \
      --bind "2:change-preview(source $ZDOTDIR/git/git.zsh; print_preview unstaged {})" \
      --bind "3:change-preview(source $ZDOTDIR/git/git.zsh; print_preview both {})" \
      --bind "0:execute(source $ZDOTDIR/git/git.zsh; print_preview staged {})" \
      --bind "9:execute(source $ZDOTDIR/git/git.zsh; print_preview unstaged {})" \
      --bind "8:execute(source $ZDOTDIR/git/git.zsh; print_preview both {})" \
      --bind "s:execute-silent(source $ZDOTDIR/git/git.zsh; stage_file {})+reload-sync(source $ZDOTDIR/git/git.zsh; enhanced_git_status)+down" \
      --bind "u:execute-silent(source $ZDOTDIR/git/git.zsh; unstage_file {})+reload-sync(source $ZDOTDIR/git/git.zsh; enhanced_git_status)+up" \
      --bind "S:execute-silent(source $ZDOTDIR/git/git.zsh; stage_all)+reload-sync(source $ZDOTDIR/git/git.zsh; enhanced_git_status)" \
      --bind "U:execute-silent(source $ZDOTDIR/git/git.zsh; unstage_all)+reload-sync(source $ZDOTDIR/git/git.zsh; enhanced_git_status)" \
      --bind "alt-s:execute(source $ZDOTDIR/git/git.zsh; patch_stage_file {})+reload-sync(source $ZDOTDIR/git/git.zsh; enhanced_git_status)+down" \
      --bind "alt-u:execute(source $ZDOTDIR/git/git.zsh; patch_unstage_file {})+reload-sync(source $ZDOTDIR/git/git.zsh; enhanced_git_status)+up" \
      --bind "ctrl-alt-r:execute-silent(source $ZDOTDIR/git/git.zsh; reset_file {})+reload-sync(source $ZDOTDIR/git/git.zsh; enhanced_git_status)+down" \
      "$@"
}

# Git aliases
#############
# alias gst="git status"
alias gpl="git pull"
alias gps="git push"
alias gpsf="git push --force-with-lease"
alias gf="git fetch"

alias gc="gst && git commit"
alias gca="git add . && git commit"
alias gcam="gst && git commit --amend --no-edit"
alias gcaam="git add . && git commit --amend --no-edit"

# Interactive branch switch
gsw() {
  local branch
  branch=$(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes | grep -v '\->' | fzf)
  [[ -z "$branch" ]] && return

  if [[ "$branch" == origin/* ]]; then
    git switch --track "${branch}"
  else
    git switch "$branch"
  fi
}

gco() {
  echo -n "New branch name: "
  read branch
  [[ -z "$branch" ]] && echo "Aborted." && return 1
  git switch -c "$branch"
}

alias gprstale="git branch -v | grep '\[gone\]' | awk '{print \$1}' | xargs -r git branch -D"
alias gprstaleman="git branch -v | fzf -m --reverse --info=inline | awk '{print \$1}' | xargs -r git branch -D"

# Logs
alias glog="git log --pretty=format:'%C(auto)%h%C(reset) %C(auto)%d%C(reset) %s %C(cyan)[%an]%C(reset) %C(dim white)(%cr)%C(reset)' --abbrev-commit --date=relative"
alias glogg="git log --graph --pretty=format:'%C(auto)%h%C(reset) %C(auto)%d%C(reset) %s %C(cyan)[%an]%C(reset) %C(dim white)(%cr)%C(reset)' --abbrev-commit --date=relative"

alias gbsc="git bisect start"
alias gbsg="git bisect good"
alias gbsb="git bisect bad"
alias gbsr="git bisect reset"

gfix() {
  local commit
  commit=$(glog | fzf --ansi --height=40% --reverse --prompt="Pick commit to fixup > ")
  [[ -z "$commit" ]] && echo "Aborted." && return 1

  local commit_hash=$(echo "$commit" | awk '{print $1}')
  echo "Fixing up: $commit"

  # Stage interactively using your gst tool
  gst || { echo "Staging failed or cancelled."; return 1; }

  # Commit as fixup into selected commit
  git commit --fixup="$commit_hash"
}
