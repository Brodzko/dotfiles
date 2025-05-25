source "$ZDOTDIR/chalk.zsh"
source "$ZDOTDIR/fancy_symbols.zsh"
source "$ZDOTDIR/gitlab/queries/models.zsh"

# Gets MR IID from list item
get_mr_iid() {
  echo $1 | awk -F"[][]" '{print $2}'
}

print_ci_status_icon() {
  if [[ $1 == "SUCCESS" ]]; then
    echo -n "$(chalk green bold $SYM_CI_SUCCESS)"
  elif [[ $1 == "FAILED" ]]; then
    echo -n "$(chalk red bold $SYM_CI_FAILED)"
  elif [[ $1 == "RUNNING" ]]; then
    echo -n "$(chalk cyan bold $SYM_CI_RUNNING)"
  else
    echo -n "$(chalk bright_black bold $SYM_CI_CANCELLED)"
  fi
}

print_ci_status_detail() {
  if [[ $1 == "success" ]]; then
    echo -n "$(chalk green bold "$SYM_CI_SUCCESS Pipeline succeeded")"
  elif [[ $1 == "failed" ]]; then
    echo -n "$(chalk red bold "$SYM_CI_FAILED Pipeline failed")"
  elif [[ $1 == "running" ]]; then
    echo -n "$(chalk cyan bold "$SYM_CI_RUNNING Pipeline running")"
  else
    echo -n "$(chalk bright_black bold "$SYM_CI_CANCELLED Pipeline cancelled/unavailable/unknown")"
  fi
}

print_reviewers() {
  local -a reviewers
  IFS=',' read -rA reviewers <<<"$1"

  for r in "${reviewers[@]}"; do
    echo "- $(chalk yellow bold $r)"
  done
}

print_approved() {
  local csv=$1
  local approvers=(${(s:,:)csv})
  local target="Martin Brodziansky"

  if [[ ${approvers[(ie)$target]} -le ${#approvers} ]]; then
    echo "$SYM_EYE_CHECK "
  else
    echo ""
  fi
}

parse() {
  echo "$1" | jq -r "$2"
}

print_mr_listitem() {
  while read -r json_line; do
    IFS=$'\t' read -r "${(@)model_mr_keys}" <<<"$(jq -r "[$model_mr_paths] | @tsv" <<<"$json_line")"

    if [[ $draft == "true" ]]; then
      color="magenta"
    elif [[ $state == "opened" ]]; then
      color="green"
    else
      color="red"
    fi
    echo -n "$(chalk bright_red bold "$(print_approved $approved_by)")"
    echo -n "$(chalk $color "$(lpad "$(trunc "![$iid]" 8)" 8)") "

    echo -n "$title "
    echo -n "$(chalk cyan "($author)") "
    echo -n "$(chalk dim "($(date_diff $created_at))")"

    local encoded=$(printf %s "$json_line" | base64)
    # Stuff after separator is invisible but available for functions, pass the whole MR model
    echo -n '::::::'
    echo $encoded
  done;
}

print_mr_detail() {
  local mr=$(cat)

  IFS=$'\t' read -r "${(@)model_mr_keys}" <<<"$(jq -r "[$model_mr_paths] | @tsv" <<<"$mr")"

  echo -n "$(print_ci_status_icon $pipeline_status)"
  echo -n " "
  echo -n "$(chalk magenta bold $title)"
  echo -n " "
  echo "($(chalk dim yellow $author))"
  echo "   $(chalk dim blue "$SYM_MR [$source_branch → $target_branch]") "
  if [[ $conflicts == "true" ]]; then
    echo "   $(chalk red bold "$SYM_GIT_COMPARE Merge conflicts detected.")"
  fi
  echo "   $(print_ci_status_detail $pipeline_status)"
  if [[ $approved == "true" ]]; then
    echo "   $(chalk green bold "$SYM_CI_SUCCESS Approved.")"
  else
    echo "   $(chalk blue bold "$SYM_EYE Needs review.")"
  fi
  echo " "
  if [[ $reviewers == "-" ]]; then
    echo "No reviewers"
  else
    echo "Reviewers:"
    print_reviewers $reviewers
  fi
  echo
  echo $description
  echo
}
