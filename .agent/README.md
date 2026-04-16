# Agent Skills & Context Architecture

This directory organizes guidance for AI agents (and human developers) into two complementary layers:

## Skills (`.agent/skills/`)

**How to do things.** Executable recipes and workflows.

- `testing.md` — How to run tests, understand test structure, common pitfalls
- `lint.md` — How to run linting and formatting
- `seed.md` — How to populate the database with demo data
- `db_migrate.md` — How to create and run migrations

Each skill includes:
- **Standalone Mode**: What a developer does manually without AI
- **Judgment Calls**: When to use this skill vs. alternatives
- **Common Pitfalls**: Gotchas to avoid

## Localized Context

**What to know when working in a specific area.** Domain knowledge that's only relevant in certain directories.

- `app/controllers/dashboard/AGENTS.md` — Baker-facing logic, ownership checks, event lifecycle
- `app/controllers/shop/AGENTS.md` — Customer-facing logic, inventory locking, unsubscribe flow
- `app/assets/stylesheets/AGENTS.md` — Design system tokens, layout primitives, CSS constraints
- `test/AGENTS.md` — Testing strategy, auth bypass details, system test file index

Each localized file is self-contained for its directory. When an AI (or developer) is working in that area, these files provide context without bloating the global knowledge.

## Root Context

`../AGENTS.md` contains global project info: tech stack, domain models, authentication flow, coding conventions. It's loaded on every interaction.

## Design Philosophy

**Separate knowledge from execution. Separate global from local.**

- Knowledge is stable, rarely changes, and lives in Markdown files that get reviewed in PRs.
- Execution (commands, tools, APIs) changes more often and lives in skills that can be updated independently.
- Global context is lean and points to localized context files. This keeps the context window budget focused on the area being worked on.

**Avoid staleness by documenting patterns, not inventories.** Don't list "all the CSS classes" or "all the controller methods." Document the *rules and constraints* that govern them. When something is deleted or refactored, the documentation doesn't need to change.

## When to Add or Update

### Add a new skill when:
- You have a multi-step workflow that needs to be repeatable and teachable
- The workflow has judgment calls or common pitfalls worth documenting
- Multiple people (or AIs) will use it

### Add a new localized AGENTS.md when:
- A directory has domain-specific rules or patterns that AIs should know
- Those rules differ from the global conventions
- The directory is complex enough to warrant context

### Remove or simplify when:
- A skill's command becomes outdated → update the skill once, everywhere is fixed
- A localized file documents implementation details (specific class names, method lists) → delete those lines; keep the patterns
- Something is no longer true → remove it, don't comment it out

## Example: Staying Fresh

**Before (stale)**: Root AGENTS.md lists 30 CSS classes and all their properties. Someone deletes `.card-accent`. Now the docs are wrong.

**After (fresh)**: Stylesheets AGENTS.md documents the *design system constraints* (3 spacing sizes, no new utilities without justification) and provides a table of major component types. Specific class details live in the stylesheet itself. When something is deleted, the doc stays accurate because it didn't enumerate implementation.
