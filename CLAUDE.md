## Project Reference

- **AGENTS.md** — Global project info (tech stack, domain models, conventions)
- **`.agent/skills/`** — Runnable task workflows and principles
  - `code-principles.md` — Andrej Karpathy's framework (Think, Simplicity, Surgical, Goal-Driven)
  - `testing.md`, `lint.md`, `seed.md`, `db_migrate.md` — Task workflows
- **`.agent/README.md`** — Skills + Localized Context architecture overview

## Localized Context

When working in specific areas, see:

- **`app/controllers/dashboard/AGENTS.md`** — Baker-facing logic, ownership patterns
- **`app/controllers/shop/AGENTS.md`** — Customer-facing logic, inventory locking
- **`app/views/AGENTS.md`** — Partial philosophy, rendering conventions
- **`app/assets/stylesheets/AGENTS.md`** — Design system constraints
- **`test/AGENTS.md`** — Testing strategy, auth bypass details

## Workflow

**You always handle git.** Claude writes code, commits to the branch, and suggests changes. You review, run tests, and push. Claude never creates branches, creates commits, or opens PRs.

**GitHub CLI.** Always use the `gh` CLI (installed via homebrew) for GitHub operations—viewing PRs, checking issues, fetching issue details, etc. Use `gh pr view`, `gh issue view`, `gh api`, etc. rather than web navigation or URL guessing.

## Testing & Verification

**Manual testing after implementation (token-efficient)**
1. Claude implements feature and commits
2. You run `bin/validate` to test
3. Share test results with Claude
4. Claude iterates based on actual failures, not hypothetical ones

**This approach:**
- Avoids expensive test scripts and elaborate verification upfront
- Lets you validate in your own environment
- Focuses Claude's token budget on correctness, not verification
- Enables faster iteration cycles
