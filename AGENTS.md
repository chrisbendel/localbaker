# Project: Bread Orders (Rails 8.1.1)

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
- **Mobile First**: All layouts prioritize small screens. Use flexbox as the primary layout engine.
- **Web Standards**: Native browser features (Flexbox, CSS custom properties) over JavaScript-driven UI.
- **Token-driven CSS**: All colors, spacing, and shape values come from CSS custom properties defined in `:root`. No hardcoded values in views or components.
- **Modular Design**: Rails partials as components. Keep partials focused and reusable.
- **No Dropdowns**: Avoid JS-dependent UI patterns.
- **No Emoji**: Keep the UI text-only and clean. Unicode punctuation (arrows, middots) is fine; emoji are not.

## UI & CSS Architecture

### Design Tokens (`app/assets/stylesheets/application.css`)

All values come from `:root` custom properties:

```css
--font             /* system-ui stack */
--text             /* #111 — primary text */
--text-muted       /* #666 — secondary text */
--border           /* #ddd — default borders */
--border-strong    /* #999 — emphasized borders */
--bg               /* #fff */
--bg-subtle        /* #f6f6f6 — cards, panels */
--success / --success-bg / --success-border
--danger  / --danger-bg  / --danger-border
--sp-xs / --sp-sm / --sp-md / --sp-lg / --sp-xl / --sp-2xl  /* spacing scale */
--radius           /* 3px */
--radius-full      /* 9999px — pills */
```

### Layout Primitives

| Class | Purpose |
|---|---|
| `.container` | Max-width 720px, centered, horizontal padding |
| `.stack` | Vertical flex column, `gap: --sp-md` |
| `.stack-sm` | Vertical flex column, `gap: --sp-sm` |
| `.stack-lg` | Vertical flex column, `gap: --sp-xl` |
| `.group` | Horizontal flex row, `gap: --sp-sm` |
| `.group-lg` | Horizontal flex row, `gap: --sp-lg` |
| `.grid` | CSS grid, `gap: --sp-lg` |
| `.grid-cols-2` | 2-column grid (≥768px) |
| `.grid-cols-3` | 3-column grid (≥768px) |
| `.grid-sidebar` | `1fr 320px` layout for content + aside (≥768px) |

### Components

| Class | Purpose |
|---|---|
| `.card` | Bordered box, `1px solid var(--border)`, minimal radius |
| `.card-accent` | Card with a bold left border (event details) |
| `.panel` | Subtle background container (`--bg-subtle`) |
| `.empty-state` | Dashed border centered placeholder |
| `.nudge` | Subtle next-step prompt (subtle bg + border) |
| `.badge` | Pill badge — variants: `.available`, `.sold-out`, `.draft` |
| `.order-confirmed` | Green callout for saved order confirmation |

### Buttons

| Class | Purpose |
|---|---|
| `button` / `.button` | Default bordered button |
| `.primary` | Filled black button (primary CTA) |
| `.small` | Compact button size |
| `.secondary` | Muted/ghost button |
| `.danger` | Red-tinted destructive action |
| `.button-link` | Unstyled inline link-style button (used for `button_to`) |

### Typography Helpers

`.text-muted`, `.text-sm`, `.text-lg`, `.text-danger`, `.text-success`, `.font-bold`, `.text-center`, `.text-right`, `.section-title`

### Tables

Global `table` styles apply to all tables. Use `.responsive-table` + `data-label="..."` on `<td>` for mobile card fallback (stacks rows at ≤600px).

## Application Structure

### Domain Models

| Model | Description |
|---|---|
| `User` | Email-based account. Can be a baker (has store) and/or customer (has orders). |
| `Store` | Baker's storefront. One per user. Has a `slug` for public URL. |
| `Event` | A bake/pickup event. Draft until `published_at` is set. |
| `EventProduct` | A product in an event (name, quantity, price_cents). |
| `Order` | One order per user per event. |
| `OrderItem` | Line item in an order. Captures `unit_price_cents` at order time. |
| `LoginCode` | OTP for passwordless email auth. BCrypt digest, 10-min TTL, 5/hr rate limit. |
| `StoreNotification` | Email subscription for a store. Has `unsubscribe_token`. |

### Controllers

Two namespaces:
- `Stores::` — baker-facing event/product management (authenticated, ownership-checked)
- `Storefront::` — customer-facing ordering flow (public store, authenticated ordering)

Key controllers:
- `SessionsController` — passwordless OTP auth (create → verify → confirm)
- `DashboardController` — hub for baker tools + customer orders
- `StorefrontController` — public store page
- `Storefront::OrderItemsController` — add/update/remove cart items (uses `with_lock` for inventory race conditions)
- `PublicUnsubscribesController` — email unsubscribe via token

### Routing Shape

```
/                          → SessionsController#new (sign in)
/dashboard                 → DashboardController#index
/store                     → StoresController (singular resource)
  /events                  → Stores::EventsController
    /event_products        → Stores::EventProductsController (shallow)
/s/:slug                   → StorefrontController#show (public)
  /s/:slug/events/:id      → Storefront::EventsController#show
    /order_items           → Storefront::OrderItemsController
  /s/:slug/notification    → Storefront::NotificationsController
/unsub/:token              → PublicUnsubscribesController#unsubscribe
/test/sign_in/:user_id     → Test::AuthController#create (test env only)
```

### Views & Partials

```
layouts/application.html.erb       — container, header, flash toast
application/_header.html.erb       — logo + nav (Storefront/Manage gated on store.persisted?)
storefront/_store_hero.html.erb    — store name + back link
storefront/_event_list_item.html.erb — public event card
storefront/_event_details.html.erb — event info card on order page
storefront/_product_card.html.erb  — product with Add to Order button
storefront/_order_summary.html.erb — order sidebar with +/- controls + confirmation callout
stores/event_products/_form.html.erb — shared product form
```

### Page Titles

Every view sets a contextual `content_for :title`. Convention:
- Public storefront: `Store Name`
- Public event: `Event Name — Store Name`
- Baker management: `Store Name — Context` (e.g. `Morning Loaf — Events`)
- Auth pages: `Sign in`
- Fallback (layout default): `Bread Orders`

## Authentication

Passwordless OTP flow:
1. User submits email → `SessionsController#create`
2. `LoginCode.generate_for(user)` — BCrypt digest stored, plain code emailed
3. User submits 6-digit code → `SessionsController#confirm`
4. BCrypt compare → `sign_in(user)` sets `session[:user_id]`

Rate limiting: 5 codes per hour per user (enforced in `LoginCode.generate_for`).

## Testing

### Commands

```bash
bin/rails test          # unit + integration (fast)
bin/rails test:system   # browser/system tests only
bin/rails test:all      # everything
```

### System Tests

Two full lifecycle tests in `test/system/`:
- `baker_lifecycle_test.rb` — full baker journey (sign in through sign out)
- `customer_lifecycle_test.rb` — full customer journey (sign in through sign out)

System tests use a **test-only sign-in bypass** instead of the OTP email flow:
- Route: `GET /test/sign_in/:user_id` (only registered when `Rails.env.test?`)
- Controller: `app/controllers/test/auth_controller.rb`
- Helper: `sign_in_via_browser(user)` in `test/application_system_test_case.rb`

The OTP flow itself is covered by `test/controllers/sessions_controller_test.rb`.

### Test Helper

`test/test_helper.rb` provides `sign_in_as(user)` for controller/integration tests — goes through the full OTP flow by reading from `ActionMailer::Base.deliveries`.

## Coding Conventions

- **Style**: StandardRB. Run `bundle exec standardrb --fix` before committing.
- **Architecture**: Conventional Rails — RESTful controllers, logic in models, thin controllers.
- **Queries**: Use `includes` to avoid N+1s. Check controller `show` actions when adding associations to views.
- **Prices**: Stored as integer cents (`price_cents`). Use `price_formatted` and `number_to_currency` helpers for display.
- **Inventory**: `EventProduct#remaining` and `sold` are calculated, not stored. `with_lock` used in `OrderItemsController` to prevent race conditions.
- **Authorization**: No gem — manual `current_user == @store.user` ownership checks. `require_authentication!` before_action for protected routes.
- **No inline styles**: All styling via CSS classes and tokens. Inline `style=` attributes are a code smell.

## Development Workflow

```bash
bundle install && bin/rails db:prepare   # setup
bin/rails server                          # run
bin/rails test:all                        # full test suite
bundle exec standardrb --fix             # lint + fix
bin/rails routes                          # inspect routes
bin/rails console                         # REPL
bin/rails db:seed                         # seed demo data
```

### Seed Accounts (after `db:seed`)

- **Baker**: `baker@example.com` — store at `/s/the-crusty-loaf`
- **Buyer 1**: `buyer1@example.com`
- **Buyer 2**: `buyer2@example.com`

## AI Interaction Guidelines

- Use minimal, well-scoped changes.
- Add or update tests for any behavior changes. System tests for user-facing flows, controller tests for auth/authorization.
- Keep tooling consistent: use `bin/rails` and `bundle exec`.
- Follow feature branch naming: `feat/...`, `fix/...`, `chore/...`.
- Use conventional commit messages.
- Do not add inline `style=` attributes — use CSS classes and tokens.
- Do not introduce new CDN dependencies — assets are self-hosted via Propshaft.
- Do not use emoji in views or copy.
