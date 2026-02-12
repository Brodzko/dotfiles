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

## Adaptive Learning

When corrected or redirected on how this skill is used:

1. **Detect the correction**: Recognize when the user corrects your behavior, invocation pattern, option formatting, or any other aspect of how this skill operates
2. **Internalize immediately**: Apply the correction for the rest of the current session
3. **Propose a permanent change**: Ask: _"Do you want to change this skill's workflow like this: [describe the specific change]?"_
4. **If confirmed**: Update this SKILL.md file yourself with the new behavior — integrate it naturally into the relevant section (don't just append)
5. **If declined**: Continue with the correction for this session only
