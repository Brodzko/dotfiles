---
name: user-input
description: Ask user to pick from options. Provide a question (with context) and newline-separated options.
---

# User Input Skill

Present options to the user via a fuzzy-searchable picker in iTerm2.

## API

```sh
~/.config/amp/skills/user-input/amp-input '<question>' '<options>'
```

- **question**: What you're asking, with enough context for the user to understand
- **options**: Newline-separated list of choices

The script opens an iTerm2 tab, shows the picker, returns the selection, and auto-closes.

## Example

```sh
~/.config/amp/skills/user-input/amp-input "Which MR to review?" "123 - Fix auth bug\n456 - Add caching\n789 - Refactor API"
```

## When to Use

Use proactively when the user needs to pick from options you can fetch:
- MRs, branches, files, issues
- IDs or URLs they'd have to look up
- Anything tedious to type

**Pattern: Fetch → Pick → Continue**
1. Fetch options (glab, git, find, etc.)
2. Format as newline-separated string
3. Call amp-input with question + options
4. Use the returned selection

## Requirements

- iTerm2 (with AppleScript enabled)
- `gum` (`brew install gum`)
