# LocalBaker

A platform for local bakers to sell directly to their community. Bakers create a storefront, post upcoming bake events with products, and accept pre-orders. Customers browse, subscribe for notifications, and place orders before pickup.

---

## How it works

**Bakers** create a store, draft events (with dates, products, and optional repeat cadence), then publish when ready. Publishing emails all store subscribers and opens the event for ordering. For repeating bakes, a draft of the next one is automatically spawned on publish.

**Customers** browse storefronts, subscribe for email notifications, and place orders through a live cart. Orders are tied to a specific pickup event.

---

## Philosophy

Complexity is inevitable — the goal is to drive it down wherever there's control over it.
Every UI decision is filtered through: *does this reduce or add to the user's cognitive load?*

---

## Stack

| Layer | Choice | Notes |
|---|---|---|
| Framework | Rails 8.1 | Full-stack conventions, Hotwire, no SPA complexity |
| Language | Ruby 4.0 | — |
| Database | SQLite3 | File-based, persistent volume on Fly.io |
| Background jobs | Solid Queue | DB-backed, no Redis |
| Cache | Solid Cache | DB-backed, no Redis |
| WebSockets | Solid Cable | DB-backed, no Redis |
| Asset pipeline | Propshaft | Minimal, no Sprockets |
| JS delivery | importmap-rails | No Node.js, no bundler, native ESM |
| Interactivity | Hotwire (Turbo + Stimulus) | SPA-like UX without a JS framework |
| Auth | Passwordless OTP | Email → 6-digit code → session. No passwords, no Devise |
| Email | Resend | Transactional delivery (dev: Letter Opener) |
| File storage | Cloudflare R2 via Active Storage | S3-compatible, cheap egress |
| Rate limiting | Rack::Attack | Request throttling at the middleware layer |
| Address parsing | StreetAddress | Normalizes freeform pickup addresses |
| Lint | StandardRB | Zero-config Ruby style enforcement |
| Testing | Minitest + Capybara | Unit, integration, and full browser system tests |
| Deployment | Fly.io | Persistent volume for SQLite |

The absence of Redis is intentional. Solid Queue, Cache, and Cable keep the infrastructure minimal — one process, one database, one volume.

## CSS

No framework. Custom stylesheet with a token-driven design system defined in `:root`:

- Spacing scale (`--sp-xs` through `--sp-2xl`), color palette, border, radius tokens
- Layout primitives: `.stack`, `.group`, `.grid`, `.grid-sidebar`
- Components: `.card`, `.panel`, `.nudge`, `.badge`, `.button`
- Philosophy: clean system HTML, no shadows, minimal border-radius, flexbox-first, mobile-first

Icons are inline SVGs. No icon library dependency.

## Auth

Passwordless. Enter an email address → receive a 6-digit OTP → verify to sign in. New accounts are created automatically on first sign-in. No passwords stored, no Devise.

## PWA

Installable as a Progressive Web App. Service worker registered on load, manifest served at `/manifest`.

---

## Testing

The test suite covers:

- **Unit/integration**: models, controllers, mailers — parallelized across 10 processes
- **System tests**: full browser flows via Capybara + headless Chrome, covering the complete baker lifecycle (store → event → products → publish → orders) and customer lifecycle (browse → subscribe → order → manage cart)

All dates in tests are relative (`n.days.from_now`) — no hardcoded dates that rot.

```sh
bin/validate          # lint + unit/integration + system (recommended)
bin/rails test        # unit + integration only
bin/rails test:system # browser tests only
```

---

## Development

```sh
brew install rbenv
rbenv install        # reads .ruby-version
bundle install
bin/rails db:prepare
bin/rails s          # http://localhost:3000
```

Emails open in the browser via `letter_opener`.

Static analysis:

```sh
bundle exec bundler-audit update && bundle exec bundler-audit check
bundle exec brakeman -q -w2
```

---

## Deployment

```sh
fly deploy    # deploy to Fly.io
fly launch    # first-time setup
```
