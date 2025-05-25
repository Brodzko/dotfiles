ZSHRC_DIR="${0:A:h}"

source "$ZSHRC_DIR/chalk.zsh"
source "$ZSHRC_DIR/fancy_symbols.zsh"
source "$ZSHRC_DIR/utils.zsh"

# Gitlab CLI
alias mr="glab mr view"
alias mrcr="glab mr view -c"
alias mrd="glab mr diff | delta"

# alias cr="glab mr list --per-page=30 | fzf -m --reverse --info=inline --preview 'Preview here' | awk '{print substr(\$1, 2)}' | xargs -r glab mr checkout"

# Pretty-prints a MR object to a row
# Accepts tab separated values
print_mr_listitem() {
  while IFS=$'\t' read -r iid target_branch title author state draft created_at; do

    # echo $created_at
    if [[ $draft == "true" ]]; then
      color="magenta"
    elif [[ $state == "opened" ]]; then
      color="green"
    else
      color="red"
    fi

    echo -n "$(chalk $color "$(fix_length "![$iid]" 8)") "
    echo -n "$(chalk cyan "($SYM_MR $(fix_length "$target_branch" 7))") "
    echo -n "$title "
    echo -n "$(chalk yellow "($author)") "
    echo "$(chalk dim "($(date_diff $created_at))")"
  done
}

mrs() {
  glab mr list "$@" --output=json | jq -r '.[] | [.iid, .target_branch, .title, .author.name, .state, .draft, .created_at] | @tsv' | print_mr_listitem
}
