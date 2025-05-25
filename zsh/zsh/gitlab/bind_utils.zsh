source "$ZDOTDIR/gitlab/queries/models.zsh"

checkout_mr() {
  if [[ -n $1 ]]; then
    echo "Checking out merge request branch..."
    glab mr checkout $1
    echo "Checked out to $1"
  else
    echo "Wrong MR IID: $1"
  fi
}

diff_mr() {
  local mr=$(cat)
  IFS=$'\t' read -r "${(@)model_mr_keys}" <<<"$(jq -r "[$model_mr_paths] | @tsv" <<<"$mr")"

  if [[ -n $iid ]]; then
    echo "Grabbing MR diff..."
    glab mr diff $iid| delta
  else
    echo "Wrong MR IID: $mr"
  fi
}

show_mr_ci() {
  if [[ -n $1 ]]; then
    glab ci view $1
  else
    echo "Wrong target branch: $1"
  fi
}

approve_mr() {
  if [[ -n $1 ]]; then
    echo "Approving MR..."
    glab mr approve $1
    echo "Approved!"
  else
    echo "Wrong MR IID: $1"
  fi
}

revoke_mr() {
  if [[ -n $1 ]]; then
    echo "Revoking MR..."
    glab mr revoke $1
    echo "Revoked!"
  else
    echo "Wrong MR IID: $1"
  fi
}
