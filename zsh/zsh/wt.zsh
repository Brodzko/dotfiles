# wt — git worktree launcher with tmux session management
#
# Usage:
#   wt              — fzf-select from existing worktrees, or create new
#   wt <slug>       — open existing worktree by slug (or create if not found)
#   wt rm [slug]    — remove a worktree (fzf if no slug)
#
# Convention:
#   Main repo:   ~/rossum/elis-frontend/
#   Worktrees:   ~/rossum/elis-frontend-worktrees/<slug>/
#   Tmux session: elis-frontend/<slug>
#
# Branch → slug: strip username prefix, replace / with -
#   martin/fix-editor-crash → fix-editor-crash

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_wt_pick_base_branch() {
  # fzf over remote branches, default to main
  local repo_root="$1"
  local branches
  branches="$(git -C "$repo_root" branch -r --format='%(refname:short)' 2>/dev/null \
    | sed 's|^origin/||' \
    | grep -v '^HEAD$' \
    | sort -u)"
  local choice
  choice="$(echo "$branches" | fzf --prompt="Base branch > " --height=~50% --query="develop" --select-1)"
  echo "${choice:-develop}"
}

_wt_slug_from_branch() {
  local branch="$1"
  # Strip common username prefixes (user/..., user-name/...)
  local slug="${branch#*/}"
  # If no prefix was stripped (no /), use as-is
  [[ "$slug" == "$branch" ]] && slug="$branch"
  # Replace remaining / with -
  echo "${slug//\//-}"
}

_wt_resolve_repo() {
  # Returns: repo_name, repo_root (main worktree), worktrees_dir
  # Works from inside main checkout OR inside a worktree

  local git_common_dir
  git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1

  # Resolve to absolute path
  git_common_dir="$(cd "$(dirname "$git_common_dir")" && pwd)/$(basename "$git_common_dir")"

  local repo_root
  if [[ "$git_common_dir" == */.git ]]; then
    # Inside main checkout: .git is at repo_root/.git
    repo_root="${git_common_dir%/.git}"
  elif [[ "$git_common_dir" == */.git/worktrees/* ]]; then
    # Inside a worktree: git-common-dir points to main repo's .git
    # but rev-parse --git-common-dir from a worktree returns main's .git
    repo_root="${git_common_dir%/.git}"
  else
    # Fallback: --git-common-dir might just be .git
    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
    # If we're in a worktree, toplevel is the worktree itself — we need main
    local main_wt
    main_wt="$(git worktree list --porcelain 2>/dev/null | head -1 | sed 's/^worktree //')"
    [[ -n "$main_wt" ]] && repo_root="$main_wt"
  fi

  local repo_name
  repo_name="$(basename "$repo_root")"
  local worktrees_dir="${repo_root}-worktrees"

  echo "$repo_name"
  echo "$repo_root"
  echo "$worktrees_dir"
}

_wt_list_slugs() {
  local worktrees_dir="$1"
  [[ -d "$worktrees_dir" ]] || return 0
  # List directories directly under worktrees_dir
  for d in "$worktrees_dir"/*/; do
    [[ -d "$d" ]] && basename "$d"
  done
}

_wt_open() {
  local repo_name="$1" wt_path="$2" slug="$3" first_run="${4:-0}"
  local session_name="${repo_name}/${slug}"

  # If tmux session already exists, just attach
  if tmux has-session -t "=$session_name" 2>/dev/null; then
    echo "📎 Attaching to existing session: $session_name"
    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "=$session_name"
    else
      tmux attach-session -t "=$session_name"
    fi
    return 0
  fi

  # Launch via tmuxinator
  echo "🚀 Starting session: $session_name"
  WT_PATH="$wt_path" \
  WT_SESSION="$session_name" \
  WT_BOOTSTRAP="$first_run" \
    tmuxinator start wt
}

_wt_create() {
  local repo_name="$1" repo_root="$2" worktrees_dir="$3" preset_slug="$4"

  # Fetch all remotes so branch list is fresh
  echo "📥 Fetching remotes..."
  git -C "$repo_root" fetch --all --quiet 2>/dev/null

  # Build branch list: remote branches + "[+] New branch" option
  local branches
  branches="$(git -C "$repo_root" branch -r --format='%(refname:short)' 2>/dev/null \
    | sed 's|^origin/||' \
    | grep -v '^HEAD$' \
    | sort -u)"

  local choice
  choice="$(printf '%s\n' "[+] New branch" $branches \
    | fzf --prompt="Branch > " --height=~50% --query="${preset_slug:-}")"
  [[ -z "$choice" ]] && return 0

  local branch_name slug wt_path is_new=0

  if [[ "$choice" == "[+] New branch" ]]; then
    # New branch: prompt for name, pick base
    is_new=1
    echo -n "Branch name (e.g. martin/fix-editor-crash): "
    read -r branch_name
    [[ -z "$branch_name" ]] && echo "❌ No branch name provided." && return 1

    local base_branch
    base_branch="$(_wt_pick_base_branch "$repo_root")"

    slug="$(_wt_slug_from_branch "$branch_name")"
    wt_path="${worktrees_dir}/${slug}"

    if [[ -d "$wt_path" ]]; then
      echo "⚠️  Worktree already exists at: $wt_path"
      _wt_open "$repo_name" "$wt_path" "$slug" 0
      return
    fi

    mkdir -p "$worktrees_dir"
    echo "🌿 Creating worktree: $slug (new branch: $branch_name from $base_branch)"
    # --no-track: don't set origin/develop as upstream — we want origin/<branch_name>
    git -C "$repo_root" worktree add --no-track -b "$branch_name" "$wt_path" "origin/${base_branch}" || {
      echo "❌ Failed to create worktree."
      return 1
    }
    # Set upstream to the future remote branch (will exist after first push)
    git -C "$wt_path" branch --set-upstream-to="origin/${branch_name}" 2>/dev/null || true
  else
    # Existing remote branch
    branch_name="$choice"
    slug="$(_wt_slug_from_branch "$branch_name")"
    wt_path="${worktrees_dir}/${slug}"

    if [[ -d "$wt_path" ]]; then
      echo "⚠️  Worktree already exists at: $wt_path"
      _wt_open "$repo_name" "$wt_path" "$slug" 0
      return
    fi

    mkdir -p "$worktrees_dir"
    echo "🌿 Creating worktree: $slug (existing branch: $branch_name)"
    git -C "$repo_root" worktree add "$wt_path" "$branch_name" 2>/dev/null \
      || git -C "$repo_root" worktree add --track -b "$branch_name" "$wt_path" "origin/${branch_name}" || {
      echo "❌ Failed to create worktree."
      return 1
    }
  fi

  echo "✅ Worktree created at: $wt_path"
  _wt_open "$repo_name" "$wt_path" "$slug" 1
}

_wt_remove() {
  local repo_name="$1" repo_root="$2" worktrees_dir="$3" slug="$4"

  # If no slug, fzf select
  if [[ -z "$slug" ]]; then
    local slugs=()
    slugs=($(_wt_list_slugs "$worktrees_dir"))
    if [[ ${#slugs[@]} -eq 0 ]]; then
      echo "No worktrees found."
      return 0
    fi
    slug="$(printf '%s\n' "${slugs[@]}" | fzf --prompt="Remove worktree > " --height=~50%)"
    [[ -z "$slug" ]] && return 0
  fi

  local wt_path="${worktrees_dir}/${slug}"
  local session_name="${repo_name}/${slug}"

  if [[ ! -d "$wt_path" ]]; then
    echo "❌ Worktree not found: $wt_path"
    return 1
  fi

  # --- Show a clear summary of what will be destroyed ---
  local has_changes=0
  local has_session=0
  local branch=""

  if git -C "$wt_path" status --porcelain 2>/dev/null | grep -q .; then
    has_changes=1
  fi
  if tmux has-session -t "=$session_name" 2>/dev/null; then
    has_session=1
  fi
  # Get the actual branch from the worktree, fall back to grep by slug
  branch="$(git -C "$wt_path" rev-parse --abbrev-ref HEAD 2>/dev/null)" || branch=""
  [[ -z "$branch" || "$branch" == "HEAD" ]] && \
    branch="$(git -C "$repo_root" branch --list | grep -F "$slug" | head -1 | sed 's/^[* ]*//')"

  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║           ⚠️   WORKTREE REMOVAL SUMMARY              ║"
  echo "╠══════════════════════════════════════════════════════╣"
  echo "║  Slug:       $slug"
  echo "║  Path:       $wt_path"
  [[ -n "$branch" ]] && \
  echo "║  Branch:     $branch"
  [[ $has_session -eq 1 ]] && \
  echo "║  Tmux:       $session_name (running — will be killed)"
  [[ $has_changes -eq 1 ]] && \
  echo "║  ⚠️  WARNING: has uncommitted changes!"
  echo "╠══════════════════════════════════════════════════════╣"
  echo "║  This will:                                          ║"
  echo "║    • Delete the worktree directory                   ║"
  [[ $has_session -eq 1 ]] && \
  echo "║    • Kill the tmux session + all processes           ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""

  echo -n "Proceed with removal? [y/N]: "
  read -r confirm
  [[ "$confirm" != [yY] ]] && echo "Aborted." && return 0

  # Kill tmux session if running — SIGTERM all process groups first, then destroy session
  if [[ $has_session -eq 1 ]]; then
    echo "🔪 Killing tmux session: $session_name"
    tmux list-panes -s -t "=$session_name" -F '#{pane_pid}' \
      | xargs -n 1 -I PANE_PID kill -s TERM -- -PANE_PID 2>/dev/null
    tmux kill-session -t "=$session_name"
  fi

  # Remove worktree and prune refs so git no longer considers the branch "checked out"
  echo "🗑️  Removing worktree directory..."
  git -C "$repo_root" worktree remove "$wt_path" --force 2>/dev/null || {
    rm -rf "$wt_path"
  }
  git -C "$repo_root" worktree prune

  # Offer to delete the local branch
  if [[ -n "$branch" ]]; then
    echo -n "Also delete local branch '$branch'? [y/N]: "
    read -r del_branch
    if [[ "$del_branch" == [yY] ]]; then
      git -C "$repo_root" branch -D "$branch" 2>/dev/null && echo "✅ Branch deleted." || echo "⚠️  Could not delete branch."
    fi
  fi

  echo "✅ Worktree removed."
}

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

_wt_help() {
  cat <<'EOF'
wt — git worktree launcher with tmux session management

Usage:
  wt                  fzf-select from existing worktrees, or create new
  wt <slug>           open worktree by slug (offers to create if missing)
  wt rm [slug]        remove a worktree (fzf if no slug given)
  wt help             show this help

Convention:
  Main repo:    ~/rossum/elis-frontend/
  Worktrees:    ~/rossum/elis-frontend-worktrees/<slug>/
  Tmux session: elis-frontend/<slug>

Branch → slug: strip username prefix, replace / with -
  martin/fix-editor-crash → fix-editor-crash

Must be run inside a git repo (main checkout or existing worktree).
EOF
}

wt() {
  # Handle help before repo resolution (doesn't need git context)
  case "$1" in
    -h|--help|help) _wt_help; return 0 ;;
  esac

  # Resolve repo context
  local resolve_output
  resolve_output="$(_wt_resolve_repo)" || {
    echo "❌ Not inside a git repository."
    return 1
  }
  local repo_name repo_root worktrees_dir
  repo_name="$(echo "$resolve_output" | sed -n '1p')"
  repo_root="$(echo "$resolve_output" | sed -n '2p')"
  worktrees_dir="$(echo "$resolve_output" | sed -n '3p')"

  echo "📂 Repo: $repo_name ($repo_root)"
  echo "📁 Worktrees: $worktrees_dir"

  # Handle subcommands
  case "$1" in
    rm|remove)
      shift
      _wt_remove "$repo_name" "$repo_root" "$worktrees_dir" "$1"
      return
      ;;
  esac

  # If slug provided as arg, open directly
  if [[ -n "$1" ]]; then
    local slug="$1"
    local wt_path="${worktrees_dir}/${slug}"
    if [[ -d "$wt_path" ]]; then
      _wt_open "$repo_name" "$wt_path" "$slug" 0
    else
      echo "❌ Worktree '$slug' not found at $wt_path"
      echo -n "Create it? [Y/n]: "
      read -r confirm
      [[ "$confirm" == [nN] ]] && return 0
      _wt_create "$repo_name" "$repo_root" "$worktrees_dir" "$slug"
    fi
    return
  fi

  # No args: fzf menu
  local slugs=()
  slugs=($(_wt_list_slugs "$worktrees_dir"))

  local options=()
  for s in "${slugs[@]}"; do
    # Check if tmux session is running
    local session_name="${repo_name}/${s}"
    if tmux has-session -t "=$session_name" 2>/dev/null; then
      options+=("${s} 🟢")
    else
      options+=("${s}")
    fi
  done
  options+=("[+] Create new worktree")
  options+=("[📂] Open main checkout")

  local choice
  choice="$(printf '%s\n' "${options[@]}" | fzf --prompt="$repo_name > " --height=~50% --ansi)"
  [[ -z "$choice" ]] && return 0

  case "$choice" in
    "[+] Create new worktree")
      _wt_create "$repo_name" "$repo_root" "$worktrees_dir"
      ;;
    "[📂] Open main checkout")
      _wt_open "$repo_name" "$repo_root" "main" 0
      ;;
    *)
      # Strip the running indicator
      local slug="${choice%% 🟢}"
      local wt_path="${worktrees_dir}/${slug}"
      _wt_open "$repo_name" "$wt_path" "$slug" 0
      ;;
  esac
}
