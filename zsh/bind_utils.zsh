ZSHRC_DIR="${0:A:h}"

source "$ZSHRC_DIR/preview_utils.zsh"

checkout_mr() {
  local iid=$(get_mr_iid "$1")

  if [[ -n $iid ]]; then
    echo "Checking out merge request branch..."
    glab mr checkout $iid
    echo "Checked out to $1"
  else
    echo "Wrong MR IID: $1"
  fi
}

diff_mr() {
  local iid=$(get_mr_iid "$1")

  if [[ -n $iid ]]; then
    glab mr diff $iid | delta
  else
    echo "Wrong MR IID: $1"
  fi
}
