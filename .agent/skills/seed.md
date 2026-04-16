---
description: How to seed the database with demo data
---
# Seed Skill

## Standalone Mode

Populate your development database with test accounts, stores, events, products, and orders:

```bash
bin/rails db:seed       # populate with demo data
bin/rails db:reset      # drop + recreate + seed (completely fresh start)
```

## What Gets Seeded

See `db/seeds.rb` for the complete list of accounts, stores, events, and sample orders created.

The seed script is idempotent in development — running it multiple times safely recreates demo data.

## Common Pitfalls

- `db:seed` is **additive** — running it twice creates duplicate records. Use `db:reset` for a clean slate.
- If migrations are pending, `db:seed` will fail. Run `bin/rails db:migrate` first (or use `bin/rails db:prepare` which handles both).

## Letter Opener in Development

Sign-in uses passwordless OTP. In development, Letter Opener intercepts emails instead of sending them. Check the browser-based inbox at `/letter_opener` to see OTP codes.
