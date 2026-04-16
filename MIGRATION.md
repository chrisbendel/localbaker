# Migration: Skills + Localized Context Architecture

**Completed**: April 15, 2026

## What Changed

Transitioned from a 273-line monolithic `AGENTS.md` to a distributed architecture:

### Removed
- `.agent/workflows/` — 4 workflow files (test, lint, seed, db_migrate)

### Created
- `.agent/skills/` — 4 enhanced skill files with Standalone Mode, Judgment Calls, Common Pitfalls
- `.agent/README.md` — Overview of the skills + context architecture
- `app/controllers/dashboard/AGENTS.md` — Baker-facing domain knowledge
- `app/controllers/shop/AGENTS.md` — Customer-facing domain knowledge
- `app/views/AGENTS.md` — Partial philosophy, rendering conventions, layout structure
- `app/assets/stylesheets/AGENTS.md` — Design system constraints and philosophy (not implementation details)
- `test/AGENTS.md` — Testing strategy, auth bypass, system test index

### Modified
- `AGENTS.md` — Pruned from 273 → 130 lines. Removed CSS/design, test commands, controller specifics. Added Maintenance section.
- `CLAUDE.md` — Updated `.agent/workflows/` → `.agent/skills/`

## Why This Matters

**Context Budget**: Root `AGENTS.md` dropped from ~3,000 tokens to ~1,200. Localized files (100–250 tokens each) only load when needed.

**Maintenance**: Documenting *patterns and constraints* instead of *implementation details* means docs stay fresh. Deleting a CSS class doesn't require updating AGENTS.md. The CSS file is the source of truth for class names and values; AGENTS.md documents the rules that protect the system.

**Clarity**: An AI working in `app/controllers/dashboard/` sees relevant domain knowledge immediately. No noise from unrelated areas. Similarly, an AI working on views sees partial philosophy and rendering conventions, not a restatement of CSS classes.

**Philosophy Alignment**: Views follow your WET-over-DRY philosophy with pure, simple partials rather than complex conditionally-rendered ones. Stylesheets enforce constraint-based design (3 spacing sizes, no new utilities without justification) rather than permissive growth.

## Going Forward

When you add a feature, ask these questions:

- **"Do developers need to know this pattern?"** → Update relevant localized AGENTS.md
- **"Is this a repeatable workflow?"** → Add or update `.agent/skills/`
- **"Is this specific to this codebase?"** → Put it in AGENTS.md (global or localized)
- **"Does this change often?"** → Keep it in code comments or git history, not AGENTS.md

See **Maintaining This Documentation** section in root `AGENTS.md` for detailed guidance.

## Files Not Yet Localized

Some directories don't have AGENTS.md yet because they're either:
- Standard Rails conventions (models, migrations, mailers — well-documented in Rails guides)
- Low complexity or standard patterns

If a directory develops patterns that confuse people, add a localized AGENTS.md there.

Examples of candidates:
- `app/models/AGENTS.md` — if you add domain logic that's not obvious (e.g., price handling, inventory calculation)
- `app/jobs/AGENTS.md` — if background job patterns diverge from standard
- `app/mailers/AGENTS.md` — if email sending has special rules

Don't preemptively add them — wait until they're needed.
