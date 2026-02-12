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

## Comment Style

- No kind prefixes on review comments (e.g., `suggestion:`, `nit:`, `concern:`)
  — sounds robotic
- When unsure whether something is a real issue, frame as a question rather than
  a prescriptive suggestion

## Naming Conventions

- Props types should be `ComponentNameProps`, not just `ComponentName`

## Architecture Preferences

<!-- Structural preferences discovered during reviews -->

---

# Platform-Specific Preferences

## TypeScript / React

### Like

- Functional and immutable code
- `remeda` utilities for data transformations (`R.randomInteger`, `R.truncate`, `R.indexBy`, `R.doNothing`)
- Explicit types over inference where it aids readability
- `Prettify<>` wrapper for intersection types
- Router `Link` components for navigation (enables cmd+click)

### Dislike

- Type casting (`as X`)
- Unnecessary `any` or `unknown`
- Class components
- Mutable patterns (`let`, push/mutate)
- eslint-disable comments (prefer fixing the issue)
- `condition && <Component />` in JSX - prefer ternary with explicit `null`
- `gap` on MUI Stack - prefer `spacing` + `useFlexGap`
- Custom utility functions when Remeda has equivalent

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
