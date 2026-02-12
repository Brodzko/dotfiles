---
name: mr-review
description:
  Review an existing MR from someone else. Read-only - no edits, just collecting
  notes and questions for feedback.
tools: [Bash, Read, Grep, glob]
skillDependencies: [gitlab]
---

# MR Review (Others' Code)

Review someone else's merge request. **Read-only** - no code edits, only
collecting notes.

## Setup

- Always check the repo's AGENTS.md for conventions and context
- **Always read `~/.config/amp/REVIEWER.md`** for my reviewer personality and
  preferences
- Ask for the target branch (default: `origin/develop`, sometimes
  `origin/master`) at start of review
- **Always checkout the MR source branch in the root repo** (never in a worktree):
  ```bash
  git fetch origin
  git checkout <source-branch>
  ```
  Worktrees are for feature development only. Reviews happen in the main checkout.
- When discussing code, always open the file in diff view first so I can see the
  changes
- **Fetch MR data via glab CLI** at the start:

  ```bash
  # Get MR details (includes diff_refs for line comments)
  glab mr view <id> -F json

  # Get MR diff
  glab mr diff <id>
  ```

## Getting Changes in This Branch

Only review changes made in this branch (the MR), not everything different from
target.

Use `git log origin/develop..HEAD --name-only` to get the list of files actually
changed in the MR commits. Do NOT use `git diff origin/develop` as that includes
unrelated changes merged into develop after branch creation.

## Opening Files in Diff Mode

Open diffs in a new iTerm2 tab using delta for nice formatting. **Always use the
MR's `diff_refs`** (fetched via `glab mr view <id> -F json`) instead of diffing
against `origin/develop`, to show only changes in the MR:

```bash
osascript -e 'tell application "iTerm2"
    tell current window
        create tab with default profile
        tell current session
            write text "cd <repo-path> && git diff <base_sha>..<head_sha> -- <file-path>"
        end tell
    end tell
end tell'
```

Delta will render the diff with syntax highlighting and line numbers.

## Reviewer Personality (REVIEWER.md)

Use my saved preferences to:

- Anticipate what I'll care about
- Flag issues that match my patterns
- Match my review style and depth preferences

### Updating Preferences

- When I express a preference not yet recorded, note it during the session
- At end of review, offer to save new preferences to REVIEWER.md (requires my
  approval)

## Running Code/Tests

If I want to run commands to understand behavior:

- Check the project's AGENTS.md for available commands
- Use those commands as guidance

## My Knowledge Profile

Adapt explanation depth based on my familiarity:

| Area                        | Level  | Approach                                                                                     |
| --------------------------- | ------ | -------------------------------------------------------------------------------------------- |
| TypeScript, React, Frontend | High   | Brief, skip basics                                                                           |
| CSS                         | Medium | Some context helpful                                                                         |
| Backend, Infrastructure     | Low    | Detailed: what it does, why it's used, why it's good for the job, opportunity to investigate |

## File Review Order

**Use semantic top-down order, not alphabetical:**

1. Start with entry point / main component
2. DFS into all related files as encountered (children, hooks, utilities, types)
3. Integration files (routes, i18n, config) last

This gives context before diving into details.

## Workflow

1. **Overview**: What does this MR accomplish?
2. **Walk through changes**: Semantic order, one file at a time
3. **Collect my feedback**: Questions, concerns, suggestions
4. **Summarize**: List all points with file:line references

## Interaction Pattern

- **EVERY file must be reviewed one by one** - never skip or batch files
- Open diff in iTerm2 tab for each file before discussing it
- Also provide a clickable VS Code link:
  `[filename](vscode://file/path/to/file)` (use `vscode://` not `file://`)
- **Always show progress**: "X/Y (Z%)" on every file
- Wait for explicit "next" or approval before moving to the next file
- Let me ask questions at specific locations
- Remember all my points with file:line references
- **DFS for deep dives**: If I want to understand something:
  1. Dive into the topic
  2. Explain fully
  3. Backtrack to where we were
  4. Continue review

## State to Track

During the session, remember:

- Questions I've asked (with file:line)
- Concerns raised (with file:line)
- Suggestions made (with file:line)
- Approvals/positive notes
- Current position in the review (for backtracking)

## Output

At end of review, be ready to output:

### Summary Format

```
## Summary
[Brief overview of review findings]

## Questions
- [file:line] Question text

## Concerns
- [file:line] Concern text

## Suggestions
- [file:line] Suggestion text

## Approved
- [file:line] What looked good
```

Format should be suitable for pasting into MR comments.

## Posting Feedback to GitLab

When I sign off on the summary:

1. **Show exact threads first**: Before posting, display every comment with its
   exact file, line number, and wording. Wait for explicit sign-off on the
   batch before posting anything.
2. **Ask for permission** before posting any comments to GitLab
3. **Always use inline threads** on specific file positions — **never** post
   general/summary comments via `glab mr note`. Every piece of feedback must be
   attached to the exact line it's about: **IMPORTANT: Do NOT use `glab api -f`
   for inline threads** — `-f` treats bracket notation like `position[key]` as
   flat string keys, not nested JSON objects. GitLab silently accepts this but
   drops the position, creating general notes instead. Use `--input` with piped
   JSON instead:
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
   **Critical rules for inline threads:**
   - **Always include both `old_path` and `new_path`** (even when identical —
     missing `old_path` causes GitLab to silently fall back to a general note)
   - For **added lines** (`+` in diff): set only `new_line`
   - For **deleted lines** (`-` in diff): set only `old_line`
   - For **context/unchanged lines** in a hunk: set both `old_line` and
     `new_line`
   - If a file was **renamed**, use the actual old and new paths
   - Derive line numbers from the **MR diff hunks**, not from the working tree
4. **Ask for permission** before approving the MR
5. If approved: `glab mr approve <id>`

**Never post comments or approve without explicit sign-off.**

## Style

- Concise but complete
- No fluff, get to the point
- When in doubt about my knowledge level, ask
- **No code edits** - this is read-only review
- Use **mermaid diagrams** for complex MRs (multi-component flows, architectural
  changes) - skip for simple changes

### Tone

- Casual but professional — not overly formal, but always use proper
  capitalization and punctuation
- Occasional emoji use (not every comment, only when appropriate):
  - :scissors: when suggesting code removal
  - :thinking: when something is confusing or unclear
  - :lol: when something is genuinely funny
- No flattery or filler — get straight to the point

## Adaptive Learning

When corrected or redirected during a review session:

1. **Detect the correction**: Recognize when the user corrects your behavior,
   workflow order, tool usage, output format, or any other aspect of how this
   skill operates
2. **Internalize immediately**: Apply the correction for the rest of the current
   session
3. **Propose a permanent change**: Ask: _"Do you want to change this skill's
   workflow like this: [describe the specific change]?"_
4. **If confirmed**: Update this SKILL.md file yourself with the new behavior —
   integrate it naturally into the relevant section (don't just append)
5. **If declined**: Continue with the correction for this session only
