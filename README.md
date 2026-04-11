# LocalBaker

Home bakeries, community pre-orders, zero infrastructure.

Bakers create a store, post bake events, and take orders. Customers subscribe for notifications and pickup their bread.

## Core Approach

- **Early-Web Aesthetic**: Simple UI, clean HTML, no shadows, no emoji. Mobile-first.
- **No-Node Stack**: Rails 8.1 with importmaps and Propshaft. No build steps, no NPM.
- **SQLite Everywhere**: Single-file database for data, cache, and background jobs (via Solid Queue/Cache). No Redis, no separate infra.
- **Passwordless**: OTP email login. No passwords.
- **Production-Ready**: SSL, rate limiting, and asset fingerprinting out of the box.

## Development

```bash
bin/setup  # install dependencies and prepare DB
bin/dev    # start server and background jobs
```

Emails are handled via **Letter Opener** in development (opening in your browser) and **Resend** in production.

## Testing & Validation

```bash
bin/validate # runs lint (StandardRB) + tests (Minitest/System)
```

The app includes comprehensive browser-based system tests covering the full baker and customer lifecycles.

## Deployment

Pops on **Fly.io** via persistent SQLite volumes and Cloudflare R2 for images.

```bash
fly deploy
```
