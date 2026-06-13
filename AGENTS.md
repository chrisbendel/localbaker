# Project: LocalBaker

Rails SaaS for home bakeries: pickup events, customer orders. Models, controllers, and routes are small — read the code for structure; this file only records what the code can't tell you.

## Stack (the non-obvious parts)

- Rails 8.1 / Ruby 4.0 / SQLite. Solid Queue/Cache/Cable (DB-backed — no Redis).
- No Node, no bundler: Propshaft + importmap. No CDN dependencies; assets self-hosted.
- Email: Resend (production), Letter Opener (development).
- Lint: StandardRB (not RuboCop). Tests: Minitest + Capybara. Deploy: fly.io.

## Hard Constraints

- **No emoji in UI.** Unicode punctuation is fine.
- **Mobile first**; flexbox primary; native browser features over JS-driven UI. Late-90s clean-HTML aesthetic.
- Prices are integer cents (`price_cents`); display via `number_to_currency`.
- No authorization gem — ownership is manual `current_user == @store.user` checks. Never weaken them.
- Never edit or hand-commit `db/schema.rb` — always a migration.
- All colors/spacing via CSS custom properties in `:root` — no inline styles, no hardcoded values.

## Commands

```bash
bin/validate                      # lint + full test suite — the only way to verify
bundle exec standardrb --fix      # lint
bin/rails db:prepare | console | routes
```

**Agents must not run tests.** Ask the user to run `bin/validate` and share results. See `test/AGENTS.md` for auth-bypass helpers.

## Workflow

- Claude/agents write code only. The user reviews, stages, commits, pushes, opens PRs — never the agent.
- Use the `gh` CLI for all GitHub operations.
- Branch naming: `feat/…`, `fix/…`, `chore/…`. Conventional commit messages.
- Follow `.agent/skills/code-principles.md`: think first, simplest version, surgical diffs, push back on complexity disproportionate to value.

## Localized context (read when working there)

- `app/controllers/dashboard/AGENTS.md` — ownership pattern, event lifecycle
- `app/controllers/shop/AGENTS.md` — inventory locking, ordering invariants
- `app/views/AGENTS.md` — partial rules
- `app/assets/stylesheets/AGENTS.md` — design-system constraints
- `test/AGENTS.md` — testing rules, auth bypass

## Documentation rules

Document patterns and constraints, never inventories (class lists, method lists, file indexes go stale and duplicate the code). If something is no longer true, delete it.
