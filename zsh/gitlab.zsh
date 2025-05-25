ZSHRC_DIR="${0:A:h}"

source "$ZSHRC_DIR/chalk.zsh"
source "$ZSHRC_DIR/fancy_symbols.zsh"

# Gitlab CLI
alias mr="glab mr view"
alias mrcr="glab mr view -c"
alias mrd="glab mr diff | delta"

# alias cr="glab mr list --per-page=30 | fzf -m --reverse --info=inline --preview 'Preview here' | awk '{print substr(\$1, 2)}' | xargs -r glab mr checkout"

# Pretty-prints a MR object to a row
# Accepts tab separated values
print_mr_listitem() {
  while IFS=$'\t' read -r iid target_branch title author state draft; do

    if [[ $draft == "true" ]]; then
      color="magenta"
    elif [[ $state == "opened" ]]; then
      color="green"
    else
      color="red"
    fi

    echo -n "$(chalk $color "![$iid]") "
    echo -n "$(chalk cyan "($SYM_MR $target_branch)") "
    echo -n "$title "
    echo "$(chalk yellow "($author)")"
  done
}

mrs() {
  glab mr list "$@" --output=json | jq -r '.[] | [.iid, .target_branch, .title, .author.name, .state, .draft] | @tsv' | print_mr_listitem
}
