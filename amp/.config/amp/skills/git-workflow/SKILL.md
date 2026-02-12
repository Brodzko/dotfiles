---
name: git-workflow
description: Manages git operations with controlled write access. Use for commits, branches, staging, and git history exploration.
---

# Git Workflow

Manage git operations with strict controls on what affects local/remote state.

## Permissions

### Freely Allowed (no approval needed)
- All read operations: `log`, `status`, `diff`, `show`, `blame`, `branch -l`, `stash list`, etc.
- `fetch` / `pull` (if no local conflicts)
- Staging files (`git add`)

### Allowed with Notification
- **Stashing**: Can stash/unstash, but always explain why

### Requires Explicit Approval
- **Commits** (see Commit Workflow below)
- **New branches**: Ask before creating
- **Cherry-pick**: Ask before executing
- **Reset/revert of remote commits**: If commit exists in remote, ask first

### Allowed for Local-Only
- `git reset --soft/--mixed` on local-only commits
- `git revert` of local-only commits

### Never Do
- **Push** - never push anything anywhere
- **Rebase** - user's job
- **Squash** - user's job
- **Force operations on remote commits** without approval

### Conflicts
- If conflicts occur during any operation, **stop immediately** and let user resolve

## Commit Workflow

When ready to commit:

1. **Stage** what's needed (can use partial staging)
2. **Stop and present**:
   ```
   ## Proposed Commit
   
   **Method**: [commit / fixup <target-sha> / amend]
   **Message**: <semantic commit message>
   
   **Staged changes**:
   - path/to/file1.ts (added/modified/deleted)
   - path/to/file2.ts (modified)
   
   Proceed? (y/n)
   ```
3. **Wait for approval** before executing `git commit`
4. **Never push** after committing

### Commit Principles
- Use **semantic commit messages** (feat:, fix:, chore:, refactor:, docs:, test:, etc.)
- Each commit must be **functional and complete**
- Use **fixup commits** when adding to older commits (user will squash later)
- Use **amend** only for the most recent commit
- Partial staging is encouraged for clean, atomic commits

## Semantic Commit Format

```
<type>(<optional scope>): <description>

[optional body]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`

## Adaptive Learning

When corrected or redirected on git workflow behavior:

1. **Detect the correction**: Recognize when the user corrects your behavior, permission assumptions, commit format, staging approach, or any other aspect of how this skill operates
2. **Internalize immediately**: Apply the correction for the rest of the current session
3. **Propose a permanent change**: Ask: _"Do you want to change this skill's workflow like this: [describe the specific change]?"_
4. **If confirmed**: Update this SKILL.md file yourself with the new behavior — integrate it naturally into the relevant section (don't just append)
5. **If declined**: Continue with the correction for this session only
