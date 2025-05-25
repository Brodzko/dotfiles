# Convention: key is how I refer to these values, value is a jq compatible extraction path
# The input comes from the gql query  (list_mrs.graphql)
# TODO: Key order guarantee?
default_to() {
  echo "($1 // \"$2\" | if . == \"\" then \"$2\" else . end)"
}

declare -A model_mr=(
  [iid]=$(default_to '.iid' '-')
  [draft]=$(default_to '.draft | tostring' 'false')
  [state]=$(default_to '.state' '-')
  [title]=$(default_to '.title' '-')
  [description]=$(default_to '.description' '-')
  [author]=$(default_to '.author.name' '-')
  [created_at]=$(default_to '.createdAt' '-')
  [reviewers]=$(default_to '.reviewers.nodes | map(.name) | join(",")' '-')
  [approved]=$(default_to '.approved' 'false')
  [approved_by]=$(default_to '.approvedBy.nodes | map(.name) | join(",")' '-')
  [source_branch]=$(default_to '.sourceBranch' '-')
  [target_branch]=$(default_to '.targetBranch' '-')
  [pipeline_status]=$(default_to '.headPipeline.status' '-')
  [pipeline_iid]=$(default_to '.headPipeline.iid' '-')
  [conflicts]=$(default_to '.conflicts' 'false')
  [mergeable]=$(default_to '.mergeable' 'false')
)
# For extracting using jq, will output fields as tab separated values
model_mr_paths="${(j:, :)${(@v)model_mr}}"

# For iterating over extracted tab separated values
model_mr_keys=(${(@k)model_mr})
