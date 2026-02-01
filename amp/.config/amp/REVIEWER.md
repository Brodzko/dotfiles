# Reviewer Personality

This file captures my code review preferences and evolves over time.

## Knowledge Profile

| Area | Level | Notes |
|------|-------|-------|
| TypeScript | High | |
| React | High | |
| Frontend general | High | |
| CSS | Medium | |
| Backend | Low | Need detailed explanations |
| Infrastructure | Low | Need detailed explanations |

---

# Global Preferences (Platform Agnostic)

## Patterns I Like

- Functional programming style
- Immutable data structures
- Pure functions

## Patterns I Dislike

- Mutable state where avoidable
- OOP patterns (classes, inheritance)
- Unnecessary type casting

## Naming Conventions

<!-- Naming preferences discovered during reviews -->

## Architecture Preferences

<!-- Structural preferences discovered during reviews -->

---

# Platform-Specific Preferences

## TypeScript / React

### Like

- Functional and immutable code
- `remeda` utilities for data transformations
- Explicit types over inference where it aids readability

### Dislike

- Type casting (`as X`)
- Unnecessary `any` or `unknown`
- Class components
- Mutable patterns (`let`, push/mutate)
- eslint-disable comments (prefer fixing the issue)

### Soft Dislikes (meh, not worth being nitpicky)

- Narrowing flexible types (e.g., `ReactNode` → `string`) without good reason
- Bundling unrelated changes into one MR

## CSS

<!-- CSS preferences discovered during reviews -->

## Backend

<!-- Backend preferences discovered during reviews -->

## Infrastructure

<!-- Infrastructure preferences discovered during reviews -->

---

# Review Notes

<!-- Recurring themes or notes from past reviews -->
