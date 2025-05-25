export ZSHRC_DIR="${0:A:h}"

source "$ZSHRC_DIR/chalk.zsh"
source "$ZSHRC_DIR/fancy_symbols.zsh"
source "$ZSHRC_DIR/utils.zsh"
source "$ZSHRC_DIR/preview_utils.zsh"

# Gitlab CLI
alias mr="glab mr view"
alias mrcr="glab mr view -c"
alias mrd="glab mr diff | delta"

fetch_mr_list() {
  glab mr list --order=updated_at "$@" --output=json | jq -r '.[] | [.iid, .target_branch, .title, .author.name, .state, .draft, .created_at] | @tsv' | print_mr_listitem
}

checkout_mr() {
  echo "Checking out $1"
}

mrs() {
  fetch_mr_list "$@" | fzf --ansi --reverse --info=inline --bind "ctrl-o:bell" --preview '
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
