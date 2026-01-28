source "$ZDOTDIR/chalk.zsh"
source "$ZDOTDIR/fancy_symbols.zsh"
source "$ZDOTDIR/utils.zsh"
source "$ZDOTDIR/gitlab/preview_utils.zsh"

source "$ZDOTDIR/gitlab/queries/models.zsh"

# Gitlab CLI
alias mr="glab mr view"
alias mrcr="glab mr view -c"
alias mrd="glab mr diff | delta"
alias mrc="mr_create_current"

# Configurable defaults for MR creation
: "${GITLAB_MR_DEFAULT_TARGET:=origin/develop}"

parse_gql_vars() {
  echo $1 | jq -Rn '(input | split("=")) as $kv | { ($kv[0]): ($kv[1]) } | @json'
}

# TODO: Add variables
fetch_mr_list() {
  glab api graphql \
    -f query="$(cat $ZDOTDIR/gitlab/queries/list_mrs.graphql)" \
    -F project="$1" |
    jq -c ".data.project.mergeRequests.nodes[]" | print_mr_listitem
}

mrs() {
  fetch_mr_list "elis/elis-frontend" "$@" | fzf --ansi --reverse --info=inline \
    --delimiter '::::::' --with-nth '{1}' \
    --bind "ctrl-c:become(source $ZDOTDIR/gitlab/bind_utils.zsh; echo {2} | base64 --decode | checkout_mr)" \
    --bind "ctrl-d:execute(source $ZDOTDIR/gitlab/bind_utils.zsh; echo {2} | base64 --decode | diff_mr)" \
    --bind "ctrl-p:execute(source $ZDOTDIR/gitlab/bind_utils.zsh; echo {2} | base64 --decode | show_mr_ci)" \
    --bind "ctrl-a:execute-silent(source $ZDOTDIR/gitlab/bind_utils.zsh; echo {2} | base64 --decode | approve_mr)+reload(source $ZDOTDIR/gitlab/gitlab.zsh; fetch_mr_list elis/elis-frontend \"@$\")" \
    --bind "ctrl-u:execute-silent(source $ZDOTDIR/gitlab/bind_utils.zsh; echo {2} | base64 --decode | revoke_mr)+reload(source $ZDOTDIR/gitlab/gitlab.zsh; fetch_mr_list elis/elis-frontend \"@$\")" \
    --preview 'source $ZDOTDIR/gitlab/preview_utils.zsh; echo {2} | base64 --decode | print_mr_detail' --preview-window=wrap
}

mr_create_current() {
  emulate -L zsh
  setopt pipefail

  command -v glab >/dev/null 2>&1 || { echo "glab not found" >&2; return 1; }
  command -v fzf  >/dev/null 2>&1 || { echo "fzf not found"  >&2; return 1; }

  git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { echo "Not inside a git repository" >&2; return 1; }

  local source_branch
  source_branch=$(git rev-parse --abbrev-ref HEAD) || return 1
  if [[ $source_branch == "HEAD" ]]; then
    echo "Detached HEAD; cannot determine source branch" >&2
    return 1
  fi

  # 1) Target branch selection via fzf
  local target_branch
  local -a remote_branches
  remote_branches=($(git for-each-ref --format='%(refname:short)' refs/remotes))

  target_branch=$(printf '%s\n' "$GITLAB_MR_DEFAULT_TARGET" "${remote_branches[@]}" \
    | awk '!seen[$0]++' \
    | fzf --prompt="Target branch> " --query="$GITLAB_MR_DEFAULT_TARGET" \
          --select-1 --exit-0) || return 1

  if [[ -z $target_branch ]]; then
    echo "Target branch selection cancelled" >&2
    return 1
  fi

  # Strip remote prefix (e.g. origin/develop -> develop)
  target_branch=${target_branch#*/}

  # 2) MR title prompt (default: last commit subject)
  local default_title title
  default_title=$(git log -1 --pretty=%s 2>/dev/null || echo "$source_branch")

  vared -p "MR title [$default_title]: " -c title
  [[ -z $title ]] && title=$default_title

  if [[ -z $title ]]; then
    echo "MR title cannot be empty" >&2
    return 1
  fi

  # 3) MR description prompt
  local description
  vared -p "MR description: " -c description

  # 4) Reviewer selection via fzf (multi-choice) - fetch from current project members
  # :id is resolved from git remote of current directory
  local -a reviewer_args
  local -a project_users
  project_users=($(glab api "projects/:id/users" --paginate 2>/dev/null | jq -r '.[].username'))

  if [[ ${#project_users[@]} -gt 0 ]]; then
    local -a selected
    selected=($(printf '%s\n' "${project_users[@]}" \
      | fzf --multi --prompt="Reviewers (tab to select, enter to confirm)> " \
            --no-select-1 --exit-0))

    reviewer_args=()
    local r
    for r in "${selected[@]}"; do
      reviewer_args+=(--reviewer "$r")
    done
  fi

  # 5) Get current user for assignee
  local current_user
  current_user=$(glab api "user" 2>/dev/null | jq -r '.username')

  echo "Creating MR from $source_branch to $target_branch..."
  glab mr create \
    --source-branch  "$source_branch" \
    --target-branch  "$target_branch" \
    --title          "$title" \
    --description    "$description" \
    --assignee       "$current_user" \
    --remove-source-branch \
    --squash-before-merge \
    "${reviewer_args[@]}"
}
