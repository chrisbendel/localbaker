# Project: LocalBaker (Rails 8.1.1)

A Ruby on Rails SaaS application for small home bakeries to manage pickup events and customer orders.

## Tech Stack

- **Framework**: Ruby on Rails 8.1.1
- **Language**: Ruby 4.0
- **Database**: SQLite3
- **Assets**: Propshaft (no Sprockets)
- **Frontend**: Turbo + Stimulus via importmap (no Node, no bundler)
- **Background/Infra**: Solid Queue, Solid Cache, Solid Cable (all DB-backed, no Redis)
- **Email**: Resend (production), Letter Opener (development)
- **Testing**: Minitest + Capybara/Selenium for system tests
- **Lint/Style**: StandardRB
- **Security**: bundler-audit, brakeman
- **Deployment**: fly.io

## Project Ethos

- **Simple UI**: Late-90s/early-2000s clean HTML aesthetic — no shadows, minimal border-radius, no heavy components.
- **Mobile First**: All layouts prioritize small screens. Flexbox is the primary layout engine.
- **Web Standards**: Native browser features over JavaScript-driven UI.
- **No Emoji**: UI is text-only. Unicode punctuation is fine; emoji are not.
- **Token-driven CSS**: All colors, spacing, and shape values come from CSS custom properties in `:root`.

> For design system constraints, CSS architecture, and component classes, see `app/assets/stylesheets/AGENTS.md`.

## Domain Models

| Model | Description |
|---|---|
| `User` | Email-based account. Can be a baker (has store) and/or customer (has orders). |
| `Store` | Baker's shop. One per user. Has a `slug` for public URL. `onboarding_steps` / `onboarding_complete?` track setup progress. |
| `Event` | A bake/pickup event. Draft until `published_at` is set. Supports `repeat_cadence` for recurring events. |
| `EventProduct` | A product in an event (name, quantity, price_cents). |
| `Order` | One order per user per event. |
| `OrderItem` | Line item in an order. Captures `unit_price_cents` at order time. |
| `LoginCode` | OTP for passwordless email auth. BCrypt digest, 10-min TTL, 5/hr rate limit. |
| `StoreNotification` | Email subscription for a store. Has `unsubscribe_token`. |

## Controllers

Two namespaces:

- `Dashboard::` — baker-facing event/product management (authenticated, ownership-checked). See `app/controllers/dashboard/AGENTS.md`.
- `Shop::` — customer-facing ordering flow (public store, authenticated ordering). See `app/controllers/shop/AGENTS.md`.

Other key controllers: `SessionsController` (passwordless OTP auth), `ShopController` (public store page), `PublicUnsubscribesController` (token-based email unsubscribe).

## Authentication

Passwordless OTP flow:
1. User submits email → `SessionsController#create`
2. `LoginCode.generate_for(user)` — BCrypt digest stored, plain code emailed
3. User submits 6-digit code → `SessionsController#confirm`
4. BCrypt compare → `sign_in(user)` sets `session[:user_id]`

Rate limiting: 5 codes per hour per user.

## Coding Conventions

- **Style**: StandardRB. Run `bundle exec standardrb --fix` before committing.
- **Architecture**: RESTful controllers, logic in models, thin controllers.
- **Queries**: Use `includes` to avoid N+1s.
- **Prices**: Stored as integer cents (`price_cents`). Use `price_formatted` / `number_to_currency` for display.
- **Authorization**: No gem — manual `current_user == @store.user` ownership checks.
- **Database Migrations**: Always create a migration file — never commit `db/schema.rb` directly.
- **Branch naming**: `feat/...`, `fix/...`, `chore/...`
- **No CDN dependencies**: Assets are self-hosted via Propshaft.

## Development Workflow

```bash
bundle install && bin/rails db:prepare   # setup
bin/rails server                          # run
bin/validate                              # full validation (lint + tests)
bundle exec standardrb --fix             # lint + fix
bin/rails routes                          # inspect routes
bin/rails console                         # REPL
```

> See `.agent/skills/` for runnable skill commands (testing, lint, seed, migrate).

## Testing

**Do not run tests yourself.** Ask the user to run `bin/validate` and share results.

> See `test/AGENTS.md` for testing strategy and auth bypass details.

## AI Interaction Guidelines

Follow the **Code Principles** (`.agent/skills/code-principles.md`): Think before coding, Simplicity first, Surgical changes, Goal-driven execution.

- Minimal, well-scoped changes only.
- Ask clarifying questions before writing code.
- Add or update tests for any behavior changes.
- Keep tooling consistent: use `bin/rails` and `bundle exec`.
- Use conventional commit messages.

### Git & Review Workflow

**CRITICAL: Claude does NOT commit code under any circumstances.**

Claude's role:
- Write and modify code files
- Run tests and verification locally
- Suggest changes and improvements
- Explain what was done and why

Your role (user):
- Review all code changes
- Create branches
- **Commit all changes** (Claude never commits)
- Push to remote
- Create and manage pull requests
- Merge branches

Claude stages changes and stops—you handle all git commit/branch/push operations.

## Maintaining This Documentation

This project uses a **Skills + Localized Context** architecture to keep documentation fresh and focused.

### Files to Update When You Change Code

- **Refactoring a controller?** Update the relevant localized AGENTS.md (`app/controllers/dashboard/AGENTS.md` or `app/controllers/shop/AGENTS.md`). Keep it focused on *patterns and rules*, not implementation details.
- **Changing a test command?** Update `.agent/skills/testing.md` once — that's it.
- **Adding a design constraint or CSS pattern?** Update `app/assets/stylesheets/AGENTS.md`.
- **Deleting a CSS class or controller method?** Just delete it from the code. Don't hunt for documentation to update.

### What NOT to Document

- Specific class names, method lists, or implementation details. Those belong in code comments, not AGENTS.md.
- Anything that will go stale (current PR status, temporary workarounds). Use git commit messages or issue tracking instead.
- Duplicate information. If it's in code or git history, don't repeat it in AGENTS.md.

### What SHOULD Stay in AGENTS.md

- Patterns and rules: "Ownership is always checked via `current_user == @store.user`"
- Constraints: "Spacing scale has exactly 3 sizes: sm, base, lg"
- Architectural decisions: "Inventory uses `with_lock` to prevent race conditions"
- Workflow knowledge: "Events are drafted until `published_at` is set"
