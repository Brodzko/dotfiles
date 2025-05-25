# Convention: key is how I refer to these values, value is a jq compatible extraction path
# The input comes from the gql query  (list_mrs.graphql)
declare -A model_mr=(
  [iid]=.iid 
  [draft]=.draft 
  [title]=.title 
  [description]=.description
  [author]=.author.name 
  [created_at]=.createdAt 
  [reviewers]='(.reviewers.nodes | map(.name) | join(","))'
  [approved_by]='(.approvedBy.nodes | map(.name) | join(","))'
  [source_branch]=.sourceBranch 
  [target_branch]=.targetBranch 
  [pipeline_status]=.headPipeline.status 
  [pipeline_iid]=.headPipeline.iid
)

# For extracting using jq, will output fields as tab separated values
model_mr_paths="${(j:, :)${(@v)model_mr}}"

# For iterating over extracted tab separated values
model_mr_keys="${(j:\t:)${(@k)model_mr}}"
