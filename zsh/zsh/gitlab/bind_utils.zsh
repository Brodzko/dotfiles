source "$ZDOTDIR/gitlab/queries/models.zsh"

checkout_mr() {
  local mr=$(cat)
  IFS=$'\t' read -r "${(@)model_mr_keys}" <<<"$(jq -r "[$model_mr_paths] | @tsv" <<<"$mr")"

  if [[ -n $iid ]]; then
    echo "Checking out merge request branch..."
    glab mr checkout $iid
    echo "Checked out to $iid"
  else
    echo "Wrong MR IID: $mr"
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
  local mr=$(cat)
  IFS=$'\t' read -r "${(@)model_mr_keys}" <<<"$(jq -r "[$model_mr_paths] | @tsv" <<<"$mr")"

  if [[ -n $source_branch ]]; then
    glab ci view $source_branch
  else
    echo "Wrong target branch: $source_branch"
  fi
}

approve_mr() {
  local mr=$(cat)
  IFS=$'\t' read -r "${(@)model_mr_keys}" <<<"$(jq -r "[$model_mr_paths] | @tsv" <<<"$mr")"

  if [[ -n $iid ]]; then
    echo "Approving MR..."
    glab mr approve $iid
    echo "Approved!"
  else
    echo "Wrong MR IID: $iid"
  fi
}

revoke_mr() {
  local mr=$(cat)
  IFS=$'\t' read -r "${(@)model_mr_keys}" <<<"$(jq -r "[$model_mr_paths] | @tsv" <<<"$mr")"

  if [[ -n $iid ]]; then
    echo "Revoking MR..."
    glab mr revoke $iid
    echo "Revoked!"
  else
    echo "Wrong MR IID: $iid"
  fi
}
