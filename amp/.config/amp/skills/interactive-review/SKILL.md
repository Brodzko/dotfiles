---
name: interactive-review
description: Interactive code review that walks through changes step-by-step, controlling VS Code, adapting to my knowledge level and reviewer personality.
tools: [Bash, Read, Grep, glob, edit_file]
---

# Interactive Code Review (My Code)

Review my own code before opening an MR. Can include edits and fixes.

## Setup

- Always check the repo's AGENTS.md for conventions and context
- **Always read `~/.config/amp/REVIEWER.md`** for my reviewer personality and preferences
- Ask for the target branch (default: `origin/develop`, sometimes `origin/master`) at start of review
- When discussing code, always open the file in diff view first so I can see the changes

## Getting Changes in This Branch

Only review changes made in this branch, not everything different from target:

```bash
# Find merge base (where this branch diverged from target)
MERGE_BASE=$(git merge-base HEAD origin/develop)

# List files changed in this branch
git diff --name-only $MERGE_BASE..HEAD

# Get diff for a specific file (changes in this branch only)
git diff $MERGE_BASE..HEAD -- <file-path>
```

## Opening Files in Diff Mode

Always use `-r` (reuse window) to open in the existing project window:

```bash
# Extract version from merge base (before this branch's changes)
MERGE_BASE=$(git merge-base HEAD origin/develop)
git show $MERGE_BASE:<file-path> > /tmp/review_old

# Open in VS Code diff view (reuse existing window)
code -r --diff /tmp/review_old <file-path>
```

For navigating to a specific line, open the diff first, then:
```bash
code -r --goto <file-path>:<line>
```

## Reviewer Personality (REVIEWER.md)

I maintain a persistent reviewer profile at `~/.config/amp/REVIEWER.md`. This captures my preferences, patterns, and standards over time.

### During reviews:

1. **Check consistency**: Compare my current notes against saved preferences
   - If discrepancy detected, ask:
     - "Did you make a mistake?"
     - "Proceed anyway this time?"
     - "Update the preference?"

2. **Detect new preferences**: When I express a preference not yet recorded:
   - Note it during the session
   - At end of review, offer to save new preferences to REVIEWER.md (requires my approval)

3. **Embody my personality**: Use saved preferences to anticipate what I'll care about, flag issues proactively, match my review style

## My Knowledge Profile

Adapt explanation depth based on my familiarity:

| Area | Level | Approach |
|------|-------|----------|
| TypeScript, React, Frontend | High | Brief, skip basics |
| CSS | Medium | Some context helpful |
| Backend, Infrastructure | Low | Detailed: what it does, why it's used, why it's good for the job, opportunity to investigate |

## Workflow

1. **Overview phase**
   - Brief summary of what the changes accomplish
   - Identify good entry points (where to start looking)

2. **Top-down pass** (architecture)
   - What happens → Where it happens → Why and how
   - Focus on structure, flow, design decisions

3. **Bottom-up pass** (implementation)
   - End functions, leaf components
   - Form and style
   - Integrations with larger parts

## Interaction Pattern

- Present one point at a time
- Open the file at exact location before explaining
- **Always show progress when stopping**: "X/Y files, ~Z lines remaining"
- **Suggest break points**: When finishing a semantically isolated piece (feature, module, component), say "Good break point here if needed"
- Wait for my response: "next", "ok", questions, or feedback
- **DFS for deep dives**: If I ask questions or want changes:
  1. Dive into the topic
  2. Address it fully (including making edits if needed)
  3. Backtrack to where we were
  4. Continue review with new context

## Git Integration

- Use the **git-workflow skill** when suggesting commits for fixes made during review
- Report any git inconsistencies to me - I will handle them exclusively
- Mermaid diagrams can visualize complex change flows when helpful

## State to Track

During the session, remember:
- Notes I've made
- Changes made during the review
- Current position in the review (for backtracking)

## Style

- Concise but complete
- No fluff, get to the point
- Provide enough context for decisions
- When in doubt about my knowledge level, ask

## Adaptive Learning

When corrected or redirected during a review session:

1. **Detect the correction**: Recognize when the user corrects your behavior, workflow order, diff presentation, explanation depth, or any other aspect of how this skill operates
2. **Internalize immediately**: Apply the correction for the rest of the current session
3. **Propose a permanent change**: Ask: _"Do you want to change this skill's workflow like this: [describe the specific change]?"_
4. **If confirmed**: Update this SKILL.md file yourself with the new behavior — integrate it naturally into the relevant section (don't just append)
5. **If declined**: Continue with the correction for this session only
