---
name: gitlab
description: Interact with GitLab using the glab CLI. Use for MRs, issues, pipelines, and API access. Authenticated as martin.brodziansky.
tools: [Bash]
---

# GitLab CLI (glab)

Use `glab` CLI for all GitLab operations. Already authenticated as **martin.brodziansky** on `gitlab.rossum.cloud`.

## Display Preferences

- **Discussion threads**: NEVER summarize human comments. Show them verbatim as posted.
- **File links**: Use VSCode links for file locations: `vscode://file/<absolute-path>:<line>` (e.g., `vscode://file//Users/martin.brodziansky@rossum.ai/rossum/ef1/src/file.ts:42`)

## User Context

- You represent **martin.brodziansky**
- **MAT team** (your team): jan.marsicek, serhan.guney, jan.pfajfr, filip.fabisik
- **PAT team**: pavel.sury, ondrej.matejka

## Permissions Model

- **Read operations**: Always allowed
- **Write operations**: Require explicit permission. Always ask before:
  - Commenting on MRs (`glab mr note`)
  - Approving/revoking MRs (`glab mr approve`, `glab mr revoke`)
  - Creating/closing/merging MRs
  - Any other mutating action

## Common Commands

### Merge Requests

```bash
# List MRs (sorted by updated, 50 per page)
glab mr list -o updated_at -P 50

# View MR details
glab mr view <id> -F json              # JSON output
glab mr view <id> -c                   # With comments

# View MR diff
glab mr diff <id>
glab mr diff <id> --raw               # Pipe-friendly format

# Approve MR (requires permission)
glab mr approve <id>

# Add comment (requires permission)
glab mr note <id> -m "Comment text"

# Create MR (requires permission)
glab mr create -s <source-branch> -b develop --squash-before-merge --remove-source-branch -t "feat: title" -d "Description"
```

### Issues

```bash
glab issue list
glab issue view <id>
```

### CI/CD

```bash
glab ci status                         # Current pipeline status
glab ci view                           # View current pipeline
glab job list                          # List jobs
```

## MR Discussions (Inline Code Review Threads)

### Get diff_refs (needed for creating inline threads)

```bash
glab api projects/:fullpath/merge_requests/<iid> | jq '.diff_refs'
# Returns: { base_sha, head_sha, start_sha }
```

### List all inline threads

```bash
# All inline threads with file, line, resolved status, and conversation
glab api projects/:fullpath/merge_requests/<iid>/discussions?per_page=100 | jq '
[.[] | select(.notes[0].position != null) | select(.notes[0].system == false)] 
| .[] | {
  id: .id,
  file: .notes[0].position.new_path,
  line: .notes[0].position.new_line,
  resolved: .resolved,
  thread: [.notes[] | select(.system == false) | {author: .author.username, body: .body}]
}'
```

### Create inline thread on file line (requires permission)

```bash
# First get diff_refs from MR
glab api projects/:fullpath/merge_requests/<iid>/discussions -X POST \
  -f body="Comment" \
  -f "position[position_type]=text" \
  -f "position[base_sha]=<base_sha>" \
  -f "position[head_sha]=<head_sha>" \
  -f "position[start_sha]=<start_sha>" \
  -f "position[new_path]=path/to/file.ts" \
  -f "position[new_line]=42"
```

### Reply to thread (requires permission)

```bash
glab api projects/:fullpath/merge_requests/<iid>/discussions/<discussion_id>/notes -X POST \
  -f body="Reply text"
```

### Resolve/unresolve thread (requires permission)

```bash
# Resolve
glab api projects/:fullpath/merge_requests/<iid>/discussions/<discussion_id> -X PUT \
  -f resolved=true

# Unresolve
glab api projects/:fullpath/merge_requests/<iid>/discussions/<discussion_id> -X PUT \
  -f resolved=false
```

## API Access

```bash
# GET request (uses :fullpath placeholder for current repo)
glab api projects/:fullpath/merge_requests/<iid>

# POST with fields
glab api projects/:fullpath/merge_requests/<iid>/notes -X POST -f body="Comment"
```

### Useful API Endpoints

| Endpoint | Description |
|----------|-------------|
| `projects/:fullpath/merge_requests/<iid>` | MR details (includes `diff_refs`) |
| `projects/:fullpath/merge_requests/<iid>/discussions` | Inline threads |
| `projects/:fullpath/merge_requests/<iid>/discussions/<id>/notes` | Reply to thread |

## Creating Merge Requests

Defaults (always apply unless told otherwise):
- **Target branch**: `develop`
- **Squash commits**: Always enabled (`--squash-before-merge`)
- **Delete source branch**: Always enabled (`--remove-source-branch`)
- **Title**: Semantic commit message (e.g., `feat: add user authentication`)
- **Description**: Include `Closes XXX-####` if there's an associated JIRA ticket

## Output Formats

Most commands support `-F json` for JSON output:

```bash
glab mr view <id> -F json
glab mr list -F json
```

Use `jq` for parsing:

```bash
glab mr view 123 -F json | jq '.web_url'
```
