source "$ZDOTDIR/chalk.zsh"
source "$ZDOTDIR/fancy_symbols.zsh"
source "$ZDOTDIR/utils.zsh"
source "$ZDOTDIR/gitlab/preview_utils.zsh"

source "$ZDOTDIR/gitlab/queries/models.zsh"

# Gitlab CLI
alias mr="glab mr view"
alias mrcr="glab mr view -c"
alias mrd="glab mr diff | delta"

parse_gql_vars() {
  echo $1 | jq -Rn '(input | split("=")) as $kv | { ($kv[0]): ($kv[1]) } | @json'
}

# TODO: Add variables
fetch_mr_list() {
  glab api graphql \
    -f query="$(cat $ZDOTDIR/gitlab/queries/list_mrs.graphql)" \
    -F project="$1" |
    jq -c ".data.project.mergeRequests.nodes[]" | print_mr_listitem
}

mrs() {
  fetch_mr_list "elis/elis-frontend" "$@" | fzf --ansi --reverse --info=inline \
    --delimiter '::::::' --with-nth '{1}' \
    --bind "ctrl-c:become(source $ZDOTDIR/gitlab/bind_utils.zsh; echo {2} | base64 --decode | checkout_mr)" \
    --bind "ctrl-d:execute(source $ZDOTDIR/gitlab/bind_utils.zsh; echo {2} | base64 --decode | diff_mr)" \
    --bind "ctrl-p:execute(source $ZDOTDIR/gitlab/bind_utils.zsh; echo {2} | base64 --decode | show_mr_ci)" \
    --bind "ctrl-a:execute-silent(source $ZDOTDIR/gitlab/bind_utils.zsh; echo {2} | base64 --decode | approve_mr)+reload(source $ZDOTDIR/gitlab/gitlab.zsh; fetch_mr_list elis/elis-frontend \"@$\")" \
    --bind "ctrl-u:execute-silent(source $ZDOTDIR/gitlab/bind_utils.zsh; echo {2} | base64 --decode | revoke_mr)+reload(source $ZDOTDIR/gitlab/gitlab.zsh; fetch_mr_list elis/elis-frontend \"@$\")" \
    --preview 'source $ZDOTDIR/gitlab/preview_utils.zsh; echo {2} | base64 --decode | print_mr_detail' --preview-window=wrap
}
