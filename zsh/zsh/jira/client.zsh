USER_STRING="martin.brodziansky@rossum.ai:$JIRA_API_TOKEN"

AUTH_STRING=$(echo -n "$USER_STRING" | base64)

jira_get_projects() {
  curl -v --request GET \
    --url "$JIRA_BASE_URL/rest/api/2/myself" \
    --header "Authorization: Basic $AUTH_STRING" \
    -H "X-Atlassian-Token: nocheck" \
    --header 'Accept: application/json'
}

jira_fetch_issues() {
  curl -v --request GET \
    --url "$JIRA_BASE_URL/rest/api/3/search/jql?jql=project%20%3D%20%22MAT%22" \
    --user "martin.brodziansky@rossum.ai:$JIRA_API_TOKEN" \
    --header "Accept: application/json"
}
