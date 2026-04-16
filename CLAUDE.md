## Project Reference

- **AGENTS.md** — Global project info (tech stack, domain models, conventions)
- **`.agent/skills/`** — Runnable task workflows (test, lint, migrate, seed)
- **`.agent/README.md`** — Skills + Localized Context architecture overview

## Localized Context

When working in specific areas, see:

- **`app/controllers/dashboard/AGENTS.md`** — Baker-facing logic, ownership patterns
- **`app/controllers/shop/AGENTS.md`** — Customer-facing logic, inventory locking
- **`app/views/AGENTS.md`** — Partial philosophy, rendering conventions
- **`app/assets/stylesheets/AGENTS.md`** — Design system constraints
- **`test/AGENTS.md`** — Testing strategy, auth bypass details

## Workflow

**You always handle git.** Claude writes code, runs tests, and suggests changes. You review, commit, and push. Claude never creates branches, makes commits, or opens PRs.
