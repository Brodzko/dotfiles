export ZSHRC_DIR="${0:A:h}"

source "$ZSHRC_DIR/chalk.zsh"
source "$ZSHRC_DIR/fancy_symbols.zsh"
source "$ZSHRC_DIR/utils.zsh"
source "$ZSHRC_DIR/preview_utils.zsh"

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

    echo -n "$(chalk $color "$(lpad "$(trunc "![$iid]" 8)" 8)") "
    echo -n "$(chalk cyan "$(lpad "($SYM_MR $(trunc "$target_branch" 7))" 11)") "
    echo -n "$title "
    echo -n "$(chalk yellow "($author)") "
    echo "$(chalk dim "($(date_diff $created_at))")"
  done
}

fetch_mr_list() {
  glab mr list --order=updated_at "$@" --output=json | jq -r '.[] | [.iid, .target_branch, .title, .author.name, .state, .draft, .created_at] | @tsv' | print_mr_listitem
}

mrs() {
  fetch_mr_list "$@" | fzf --ansi --reverse --info=inline --preview '
    source "$ZSHRC_DIR/preview_utils.zsh"; \
    local iid=$(echo "{}" | awk -F"[][]" "{print \$2}"); \
    glab mr show $iid --output=json | \
    jq -r ". | [
                  .iid, 
                  .source_branch, 
                  .target_branch, 
                  .title, 
                  (.description | if . == \"\" then \"No description\" else . end),
                  .author.name, 
                  .state, 
                  (.draft | tostring // \"false\"), 
                  .created_at,
                  (.head_pipeline?.id) // \"-\", 
                  (.head_pipeline?.status // \"-\"),
                  (if .reviewers | length > 0 then (.reviewers | map(.name) | join(\",\")) else \"-\" end),
                  (.has_conflicts | tostring // \"false\"),
                  (.changes_count // \"-\"),
                  (if .detailed_merge_status == \"not_approved\" then \"false\" else \"true\" end)
                ]
    | @tsv" | print_mr_detail' --preview-window=wrap
}
