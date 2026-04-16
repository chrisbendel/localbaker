---
description: How to seed the database with demo data
---
# Seed Skill

## Agent Instructions

Use this to populate a development database with test accounts, a store, events, products, and orders.

## Standalone Mode

A developer seeding manually:

```bash
bin/rails db:seed       # populate with demo data
bin/rails db:reset      # drop + recreate + seed (completely fresh start)
```

## Test Accounts (after `db:seed`)

| Role | Email | Notes |
|---|---|---|
| Baker | `baker@example.com` | Has store at `/s/the-crusty-loaf` |
| Buyer 1 | `buyer1@example.com` | |
| Buyer 2 | `buyer2@example.com` | |

> Sign-in uses passwordless OTP. In development, Letter Opener intercepts emails — check the browser-based inbox at `/letter_opener`.

## Common Pitfalls

- `db:seed` is additive — running it twice creates duplicate records. Use `db:reset` for a clean slate.
- If migrations are pending, `db:seed` will fail. Run `bin/rails db:migrate` first (or use `bin/rails db:prepare` which handles both).
