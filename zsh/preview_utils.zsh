export ZSHRC_DIR="${0:A:h}"

source "$ZSHRC_DIR/chalk.zsh"
source "$ZSHRC_DIR/fancy_symbols.zsh"

# Gets MR IID from list item
get_mr_iid() {
  echo $1 | awk -F"[][]" "{print $2}"
}

print_ci_status_icon() {
  if [[ $1 == "success" ]]; then
    echo -n "$(chalk green bold $SYM_CI_SUCCESS)"
  elif [[ $1 == "failed" ]]; then
    echo -n "$(chalk red bold $SYM_CI_FAILED)"
  elif [[ $1 == "running" ]]; then
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

print_mr_detail() {
  while IFS=$'\t' read -r \
    iid \
    source_branch \
    target_branch \
    title description \
    author \
    state \
    draft \
    created_at \
    pipeline_id \
    pipeline_status \
    reviewers \
    has_conflicts \
    changes_count \
    mergeable; do
    echo -n "$(print_ci_status_icon $pipeline_status)"
    echo -n " "
    echo -n "$(chalk magenta bold $title)"
    echo -n " "
    echo "($(chalk dim yellow $author))"
    echo "   $(chalk dim blue "$SYM_MR [$source_branch → $target_branch]") "
    if [[ $has_conflicts == "true" ]]; then
      echo "   $(chalk red bold "$SYM_GIT_COMPARE Merge conflicts detected.")"
    fi
    echo "   $(print_ci_status_detail $pipeline_status)"
    if [[ $mergeable == "true" ]]; then
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
  done
}
