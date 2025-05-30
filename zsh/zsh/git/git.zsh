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

_get_status_code() {
  local input=$1

  print "${input:0:2}"
}

_sanitize_path() {
  local str="$1"

  str="${str#[\'\"]}" # Removes a leading ' or "
  str="${str%[\'\"]}" # Removes a trailing ' or "
  echo $str
}

_get_filepath() {
  local input=$1
  # Git code
  local path_part=${input:3}

  if [[ "$path_part" =~ " -> " ]]; then
    echo "$(_sanitize_path "${path_part#* -> }")"
  else
    echo "$(_sanitize_path "$path_part")"
  fi
}

_get_oldfilepath() {
  local input=$1
  local path_part=${input:3}

  if [[ "$path_part" =~ " -> " ]]; then
    echo "$(_sanitize_path ${path_part% -> *})"
  else
    echo ""
  fi
}

enhanced_git_status() {
  local output=$(git status --porcelain)

  while IFS= read -r line; do
    local xy=$(_get_status_code $line)
    local filepath=$(_get_filepath $line)
    local original_filepath=$(_get_oldfilepath $line)

    echo -n "$(chalk $(get_status_color $xy) bold $xy) "
    if [[ -z "$original_filepath" ]]; then
      echo -n ""
    else
      echo -n "$(chalk magenta $original_filepath) -> "
    fi
    echo "$(chalk $(get_status_color $xy) $filepath)"

  done <<<"$output"
}

_generate_diff_command() {
  local input=$1

  local status_code=$(_get_status_code $input)
  local filepath=$(_get_filepath $input)
  local oldfilepath=$(_get_oldfilepath $input)

  local code_staged="${status_code:0:1}"
  local code_unstaged="${status_code:1:1}"

  local diff_kind=${2:-$(if [[ "$code_unstaged" == " " ]]; then echo "staged"; else echo "unstaged"; fi)}
  local diff_status=$(if [[ "$code_unstaged" == " " ]]; then echo "$code_staged"; else echo "$code_unstaged"; fi)

  local -a cmd_parts

  if [[ "$diff_status" == "?" ]]; then
    cmd_parts=(
      head -n 50
      "$filepath"
    )

  elif [[ "$diff_status" == "R" || "$diff_status" == "T" || "$diff_status" == "C" || "$diff_status" == "M" || "$diff_status" == "A" || "$diff_status" == "U" || "$diff_status" == "D" ]]; then
    cmd_parts=(
      git diff $(if [[ $diff_kind == "staged" ]]; then echo "--cached"; elif [[ $diff_kind == "both" ]]; then echo "HEAD"; fi)
      $(if [[ "$diff_status" == "R" || "$diff_status" == "T" || "$diff_status" == "C" ]]; then echo "-M"; fi)
      " -- "
      $(if [[ "$diff_status" == "R" || "$diff_status" == "T" || "$diff_status" == "C" ]]; then echo "$oldfilepath"; fi)
      "$filepath"
    )

  else
    cmd_parts=(
      echo "Unhandled diff status: $diff_status"
    )
  fi

  printf "%s\n" "${cmd_parts[@]}"
}

_generate_diff_format_command() {
  local input=$1
  local diff_kind=$2

  local status_code=$(_get_status_code $input)
  local filepath=$(_get_filepath $input)
  local oldfilepath=$(_get_oldfilepath $input)

  local code_staged="${status_code:0:1}"
  local code_unstaged="${status_code:1:1}"

  local diff_status=$(if [[ "$code_unstaged" == " " ]]; then echo "$code_staged"; else echo "$code_unstaged"; fi)

  local -a cmd_parts

  if [[ "$diff_status" == "?" ]]; then
    cmd_parts=(
      "bat --color=always"
    )

  elif [[ "$diff_status" == "R" || "$diff_status" == "T" || "$diff_status" == "C" ]]; then
    cmd_parts=(
      "delta --width=$FZF_PREVIEW_COLUMNS"
    )
  elif [[ "$diff_status" == "M" || "$diff_status" == "A" || "$diff_status" == "U" || "$diff_status" == "D" ]]; then
    cmd_parts=(
      "delta --width=$FZF_PREVIEW_COLUMNS"
    )
  else
    cmd_parts=(
      echo ""
    )
  fi

  printf "%s\n" "${cmd_parts[@]}"
}

_print_preview() {
  local input=$(cat)

  local -a command=($(_generate_diff_command $input $1))
  local -a format_command=($(_generate_diff_format_command $input $1))

  echo $(chalk cyan bold italic "$command")
  echo ""
  "${command[@]}" | "${format_command[@]}"
}

show_diff() {
  local input=$1
  local diff_kind=$2

  local -a command=($(_generate_diff_command $input $diff_kind))

  "${command[@]}"
}

stage_file() {
  local input=$1

  local status_code=$(_get_status_code $input)
  local filepath=$(_get_filepath $input)
  local oldfilepath=$(_get_oldfilepath $input)

  local path_to_stage=$(if [[ -z "$oldfilepath" ]]; then echo "$filepath"; else echo "$oldfilepath"; fi)

  local code_unstaged="${status_code:1:1}"

  echo "staging $path_to_stage"
  if [[ "$code_unstaged" != " " ]]; then
    git add "$path_to_stage"
  else
    echo "Nothing to stage"
  fi
}

unstage_file() {
  local input=$1

  local status_code=$(_get_status_code $input)
  local filepath=$(_get_filepath $input)
  local oldfilepath=$(_get_oldfilepath $input)

  local path_to_stage=$(if [[ -z "$oldfilepath" ]]; then echo "$filepath"; else echo "$oldfilepath"; fi)

  local code_staged="${status_code:0:1}"

  if [[ "$code_staged" != " " ]]; then
    git restore --staged "$path_to_stage"
  else
    echo "Nothing to unstage"
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
      'source $ZDOTDIR/git/git.zsh; echo {} | _print_preview' \
      --bind "1:change-preview(source $ZDOTDIR/git/git.zsh; echo {} | _print_preview staged)" \
      --bind "2:change-preview(source $ZDOTDIR/git/git.zsh; echo {} | _print_preview unstaged)" \
      --bind "3:change-preview(source $ZDOTDIR/git/git.zsh; echo {} | _print_preview both)" \
      --bind "0:execute(source $ZDOTDIR/git/git.zsh; show_diff {} staged)" \
      --bind "9:execute(source $ZDOTDIR/git/git.zsh; show_diff {} unstaged)" \
      --bind "8:execute(source $ZDOTDIR/git/git.zsh; show_diff {} both)" \
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
