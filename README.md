# LocalBaker — Quickstart

## Setup

- `brew install rbenv`
- `rbenv install`
- `rbenv init`
- `rbenv global <version>`
- `bundle install`
- `bin/rails db:prepare`

## Run

- bin/rails s # http://localhost:3000

## Frontend resources

- [Boxicons](https://v2.boxicons.com/) with [web components](https://v2.boxicons.com/usage#web-component) for icons

## Tests

- bin/rails test # all tests
- bin/rails test test/models # models only

## Lint / Format

- bundle exec standardrb
- bundle exec standardrb --fix

## Security checks

- bundle exec bundler-audit update && bundle exec bundler-audit check
- bundle exec brakeman -q -w2

## Useful Rails commands

- bin/rails routes
- bin/rails console
- bin/rake -T

## Notes

- Emails use test delivery in test env; in dev/prod set host via config.action_mailer.default_url_options
- Background jobs/cache/cable use solid_queue/solid_cache/solid_cable (DB-backed)

## Troubleshooting

- If tests complain about missing DB: run bin/rails db:prepare

## Environment variables/credentials

- `EDITOR="vim" bin/rails credentials:edit --environment production`

## Deployments

- `fly deploy` to deploy
- `fly launch` to create a new instance

## Roadmap

- buy a domain (localbread.now ?)