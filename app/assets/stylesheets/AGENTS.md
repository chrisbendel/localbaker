# Stylesheets — Design System Philosophy

**The design system is intentionally minimal and closed. Resist expansion.**

## Core Philosophy

This is a constraint-based system, not a utility library. We have exactly 3 spacing sizes. Exactly 8 colors. We say "no" to feature requests. This keeps the UI predictable and prevents visual debt.

The stylesheet (`application.css`) is the source of truth for all token values, class definitions, and implementation details. **Do not document specific class names or color values here** — they live in the CSS file and change over time. This document captures the *rules* that protect the system.

## Immutable Constraints

### Spacing: Three Sizes Only
- `--sp-sm` (0.5rem), `--sp-md` (1rem), `--sp-lg` (2rem)
- Layout primitives (`.stack-*`, `.group-*`) mirror this exactly
- **Never add new sizes** without explicit approval. If you think you need `--sp-xs` or `--sp-xl`, work through:
  1. Is one of the existing three close enough? (Slight visual difference is acceptable)
  2. Can you restructure the parent/child relationship instead?
  3. Is the element itself the wrong choice?

If genuinely blocked, **stop and explain why** to the user, citing which sizes you tried and why they don't work. Do not add silently.

### CSS Classes: Minimal Scope
Before adding a new class:
1. Does it already exist in `application.css`?
2. Can you solve this with existing primitives + modifier classes (`.items-center`, `.justify-between`)?
3. Is it used in at least two places? (Single-use styling stays inline or in component-specific rules)

New classes must solve problems that genuinely cannot be solved otherwise. Justify them in code comments if unclear.

### No Hardcoded Values
- All colors use tokens from `:root` (e.g., `var(--text)`, `var(--bg)`)
- All spacing uses tokens (e.g., `var(--sp-md)`)
- No inline `style=` attributes
- No hardcoded hex values, `rem` units, or `px` sizing in view files

### Design is Intentionally Limited
This is not a bug. We have:
- Warm/earthy palette (no bright accents, no cold blues)
- Three button variants (primary, secondary, danger)
- Three spacing sizes
- Minimal shape variation (3px radius, 9999px for pills)

This limitation is a feature. It forces intentional choices and prevents "just add a little variant" creep.

## When to Update This File

- A constraint has changed (e.g., "we're now allowing 4 spacing sizes")
- A new rule has emerged (e.g., "always test new components on mobile")
- A philosophy has shifted

Do NOT update this file to document:
- Individual class names or their properties (use the CSS file)
- Color hex values (use the CSS file)
- Specific token values (use the CSS file)
- Current state of components (use the CSS file)
