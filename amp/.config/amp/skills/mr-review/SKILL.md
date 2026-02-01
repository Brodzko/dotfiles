---
name: mr-review
description: Review an existing MR from someone else. Read-only - no edits, just collecting notes and questions for feedback.
tools: [Bash, Read, Grep, glob]
---

# MR Review (Others' Code)

Review someone else's merge request. **Read-only** - no code edits, only collecting notes.

## Setup

- Always check the repo's AGENTS.md for conventions and context
- **Always read `~/.config/amp/REVIEWER.md`** for my reviewer personality and preferences
- Ask for the target branch (default: `origin/develop`, sometimes `origin/master`) at start of review
- When discussing code, always open the file in diff view first so I can see the changes

## Getting Changes in This Branch

Only review changes made in this branch (the MR), not everything different from target.

Use `git log origin/develop..HEAD --name-only` to get the list of files actually changed in the MR commits. Do NOT use `git diff origin/develop` as that includes unrelated changes merged into develop after branch creation.

## Opening Files in Diff Mode

Open diffs in a new iTerm2 tab using delta for nice formatting:

```bash
osascript -e 'tell application "iTerm2"
    tell current window
        create tab with default profile
        tell current session
            write text "cd <repo-path> && git diff origin/develop -- <file-path>"
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
- At end of review, offer to save new preferences to REVIEWER.md (requires my approval)

## Running Code/Tests

If I want to run commands to understand behavior:
- Check the project's AGENTS.md for available commands
- Use those commands as guidance

## My Knowledge Profile

Adapt explanation depth based on my familiarity:

| Area | Level | Approach |
|------|-------|----------|
| TypeScript, React, Frontend | High | Brief, skip basics |
| CSS | Medium | Some context helpful |
| Backend, Infrastructure | Low | Detailed: what it does, why it's used, why it's good for the job, opportunity to investigate |

## Workflow

1. **Overview**: What does this MR accomplish?
2. **Walk through changes**: One location at a time
3. **Collect my feedback**: Questions, concerns, suggestions
4. **Summarize**: List all points with file:line references

## Interaction Pattern

- **EVERY file must be reviewed one by one** - never skip or batch files
- Open diff in iTerm2 tab for each file before discussing it
- Also provide a clickable VS Code link to the file: `[filename](file:///path/to/file)`
- **Always show progress**: "X/Y files, ~N remaining"
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

## Style

- Concise but complete
- No fluff, get to the point
- When in doubt about my knowledge level, ask
- **No code edits** - this is read-only review
- Use **mermaid diagrams** for complex MRs (multi-component flows, architectural changes) - skip for simple changes
