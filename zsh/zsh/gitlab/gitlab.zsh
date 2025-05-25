source "$ZDOTDIR/chalk.zsh"
source "$ZDOTDIR/fancy_symbols.zsh"
source "$ZDOTDIR/utils.zsh"
source "$ZDOTDIR/gitlab/preview_utils.zsh"

source "$ZDOTDIR/gitlab/queries/models.zsh"

# Gitlab CLI
alias mr="glab mr view"
alias mrcr="glab mr view -c"
alias mrd="glab mr diff | delta"

fetch_mr_list() {
  glab mr list --order=updated_at "$@" --output=json | jq -r '.[] | [.iid, .source_branch, .target_branch, .title, .author.name, .state, .draft, .created_at] | @tsv' | print_mr_listitem
}

parse_gql_vars() {
  echo $1 | jq -Rn '(input | split("=")) as $kv | { ($kv[0]): ($kv[1]) } | @json'
}

# TODO: Add variables
fetch_mr_list_gql() {
  glab api graphql \
    -f query="$(cat $ZDOTDIR/gitlab/queries/list_mrs.graphql)" \
    -F project="$1" |
    jq -r ".data.project.mergeRequests.nodes[] | [$model_mr_paths] | @tsv" | print_mr_listitem_2
}

mrs() {
  fetch_mr_list "$@" | fzf \
    --ansi \
    --reverse \
    --info=inline \
    --delimiter ':::' --with-nth 1 \
    --bind "ctrl-c:become(source $ZDOTDIR/gitlab/bind_utils.zsh; checkout_mr {2})" \
    --bind "ctrl-d:execute(source $ZDOTDIR/gitlab/bind_utils.zsh; diff_mr {2})" \
    --bind "ctrl-p:execute(source $ZDOTDIR/gitlab/bind_utils.zsh; show_mr_ci {3})" \
    --bind "ctrl-a:execute(source $ZDOTDIR/gitlab/bind_utils.zsh; approve_mr {2})" \
    --bind "ctrl-u:execute(source $ZDOTDIR/gitlab/bind_utils.zsh; revoke_mr {2})" \
    --preview '
    source "$ZDOTDIR/gitlab/preview_utils.zsh"; \
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
