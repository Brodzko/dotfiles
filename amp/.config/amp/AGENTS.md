# Personal Preferences

<!-- Add your personal coding preferences, conventions, and guidance here -->

## Communication Style

- Be concise and direct
- Skip unnecessary explanations
- Never lie or mislead - if uncertain, explicitly ask for assistance
- Be concise enough to read quickly, but don't omit necessary information

## Code Style (TypeScript/React)

- Never use comments disabling type or lint rules - if they complain, fix the implementation
- No `any`, `unknown`, or type casts unless absolutely necessary (explain why if used)
- Use Remeda for utility functions, prefer pipes and functional helpers: `import * as R from 'remeda'`
- React components: arrow functions, add `{ComponentName}.displayName = 'ComponentName'` at bottom, use named exports
- No default exports unless absolutely necessary (explain why if used)
- Prefer arrow functions unless special type overrides are needed

## Common Commands

<!-- Add frequently used commands for your projects:
- Build: `pnpm build`
- Test: `pnpm test`
- Lint: `pnpm lint`
-->

## Command Output

Minimize noisy output in the UI:

- **Intermediate commands** (output only for me, not you): discard entirely with `> /dev/null` or redirect to temp file
- **Partially relevant output**: filter to only the relevant parts (e.g., `jq '.title, .author'` for JSON)
- **Relevant output**: pretty-print for readability (e.g., `jq .` for JSON)
- **On error (non-zero exit)**: always show the output so I can see what went wrong

## Interactive Input (CRITICAL)

**ALWAYS use `user-input` skill when I need to pick from options** - never ask me to type in chat when options exist.

### When to use (proactively, without being asked):
- **Any list selection** - MRs, branches, files, issues, Jira tickets, reviewers, etc.
- **During other skills** - assigning reviewers, checking out branches, picking tasks
- **Deciding how to proceed** - when there are multiple valid approaches, show options
- **IDs or URLs** - anything I'd need to look up or copy-paste
- **Ambiguous requests** - when multiple interpretations exist, let me pick

**Rule: If the answer isn't free-form text, use this skill with options instead of asking me to type.**

### API:
```sh
~/.config/amp/skills/user-input/amp-input '<question with context>' '<newline-separated options>'
```

### Pattern: Fetch → Pick → Continue
1. **Fetch options** using appropriate tool (glab, git, find, jira, etc.)
2. **Format as newline-separated string**
3. **Call amp-input** with question + options
4. **Use selection** and continue

### Examples:
```sh
# Pick a branch
amp-input "Which branch?" "main\ndevelop\nfeature-x"

# Pick an MR reviewer
amp-input "Add reviewer to MR #123?" "alice\nbob\ncharlie"

# Choose next action
amp-input "How should I proceed?" "Refactor first\nAdd tests\nShip as-is"
```

## Skills

- **user-input** - Pick from options via fuzzy-search UI in iTerm2
- **gitlab** - GitLab CLI operations via `glab` (authenticated as martin.brodziansky)
- **mr-review** - MR review workflow for others' code
- **interactive-review** - Interactive review of my own code
- **git-workflow** - Controlled git operations
