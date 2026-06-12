# Agent Context Architecture

Two layers:

- **`.agent/skills/`** — how to do things: `code-principles.md` (read before any non-trivial change), plus command recipes (`testing.md`, `lint.md`, `seed.md`, `db_migrate.md`).
- **Localized `AGENTS.md` files** (dashboard, shop, views, stylesheets, test) — rules that only matter when working in that directory. Root `AGENTS.md` holds global constraints and points to them.

Rules for these files, per the evidence on agent context files: keep them minimal. Document **patterns, constraints, and non-discoverable commands** — never inventories (class lists, file indexes, model tables), which go stale and merely duplicate what agents find faster in code. When something stops being true, delete it.
