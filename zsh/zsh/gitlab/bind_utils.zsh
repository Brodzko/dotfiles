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
  if [[ -n $1 ]]; then
    echo "Grabbing MR diff..."
    glab mr diff $1 | delta
  else
    echo "Wrong MR IID: $1"
  fi
}

show_mr_ci() {
  if [[ -n $1 ]]; then
    echo "Showing MR CI status..."
    glab ci view $1
  else
    echo "Wrong target branch: $1"
  fi
}
