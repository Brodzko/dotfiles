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

## Tools & Skills

### GitLab MCP

The GitLab MCP is configured for `gitlab.rossum.cloud` with a project access token.

**Permissions Model:**
- **Read operations**: Always allowed (fetching MRs, diffs, discussions, project info)
- **Write operations**: Require explicit permission. Always ask before:
  - Commenting on MRs
  - Approving/unapproving MRs
  - Opening/closing MRs
  - Any other mutating action

**Creating Merge Requests:**
- **Target branch**: `origin/develop` (default). Ask for permission if different.
- **Squash commits**: Always enabled
- **Delete source branch on merge**: Always enabled
- **Title**: Semantic commit message describing the change (e.g., `feat: add user authentication`)
- **Description**: Include `Closes XXX-####` if there's an associated JIRA ticket

### Skills

- See `~/.config/amp/skills/mr-review/SKILL.md` for MR review workflow
