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
- **Destructive operations**: **NEVER** delete or destroy anything — no deleting branches, MRs, issues, comments, labels, pipelines, or any other resource. No exceptions.

## Common Commands

### Merge Requests

```bash
# List MRs (sorted by updated, 50 per page)
# NOTE: --state flag doesn't exist! Filter with jq instead:
# glab mr list -F json | jq '[.[] | select(.state == "opened")]'
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

### Debugging Failed MR Pipelines

This project uses child pipelines, so you need to check both parent and child:

```bash
# 1. Get pipeline ID from MR
glab mr view <iid> -F json | jq '{pipeline_id: .pipeline.id, status: .pipeline.status}'

# 2. Check for child pipelines (this project uses them)
glab api projects/:fullpath/pipelines/<pipeline_id>/bridges?per_page=100 | jq '[.[] | {name: .name, status: .status, child_id: .downstream_pipeline.id}]'

# 3. Get failed jobs from child pipeline
glab api projects/:fullpath/pipelines/<child_pipeline_id>/jobs?per_page=100 | jq '[.[] | select(.status == "failed") | {name: .name, stage: .stage, id: .id}]'

# 4. Get job logs (last 100 lines)
glab api projects/:fullpath/jobs/<job_id>/trace 2>/dev/null | tail -100
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

**Do NOT use `glab api -f`** for inline threads — `-f` treats bracket notation like `position[key]` as flat string keys, not nested JSON objects. GitLab silently accepts but drops the position. **Use `--input` with piped JSON instead.**

**Always include both `old_path` and `new_path`** — missing `old_path` also causes silent fallback to general notes.

```bash
echo '{
  "body": "Comment",
  "position": {
    "position_type": "text",
    "base_sha": "<base_sha>",
    "head_sha": "<head_sha>",
    "start_sha": "<start_sha>",
    "old_path": "path/to/file.ts",
    "new_path": "path/to/file.ts",
    "new_line": 42
  }
}' | glab api projects/:fullpath/merge_requests/<iid>/discussions -X POST --input - -H "Content-Type: application/json"
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

## Adaptive Learning

When corrected or redirected on GitLab CLI usage:

1. **Detect the correction**: Recognize when the user corrects your behavior, command usage, API patterns, output formatting, or any other aspect of how this skill operates
2. **Internalize immediately**: Apply the correction for the rest of the current session
3. **Propose a permanent change**: Ask: _"Do you want to change this skill's workflow like this: [describe the specific change]?"_
4. **If confirmed**: Update this SKILL.md file yourself with the new behavior — integrate it naturally into the relevant section (don't just append)
5. **If declined**: Continue with the correction for this session only

### Learning from CLI Failures

When a `glab` command fails (non-zero exit, unexpected output, wrong flags):

1. **Analyze the error**: Understand what went wrong (wrong flag, missing option, deprecated syntax, incorrect API endpoint)
2. **Find the correct approach**: Use `glab help <command>`, error messages, or web search to determine the right invocation
3. **Apply the fix**: Retry with the corrected command
4. **Propose a permanent update**: Ask: _"Do you want to change this skill's workflow like this: [describe what was wrong and the correct usage]?"_
5. **If confirmed**: Update the relevant command/section in this SKILL.md so the mistake is never repeated
