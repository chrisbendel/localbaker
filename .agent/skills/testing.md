---
description: How to run tests and understand the testing strategy
---
# Testing Skill

## Agent Instructions

**Do not run tests yourself.** Ask the user to run `bin/validate` and share the results. Tests (especially system tests) are slow and require a browser environment.

## Standalone Mode

A developer running tests manually:

```bash
bin/validate                   # full validation — lint + all tests (recommended)
bin/rails test                 # unit + integration only (fast, no browser)
bin/rails test:system          # system tests only (requires Chrome)
bin/rails test:all             # everything
bin/rails test test/models test/controllers   # specific directories
bin/rails test test/system/baker_lifecycle_test.rb   # single file
bin/rails test test/system/baker_lifecycle_test.rb:11  # single test by line
```

## Test Structure

| Directory | Type | Speed |
|---|---|---|
| `test/models/` | Unit | Fast |
| `test/controllers/` | Integration | Fast |
| `test/mailers/` | Mailer | Fast |
| `test/system/` | Browser (Capybara + Selenium) | Slow |

> See `test/AGENTS.md` for auth bypass details and system test descriptions.

## Judgment Calls

- **Unit or system?** New model logic → unit test. New user-facing flow → system test. Auth/authorization → controller test.
- **Controller test vs. system test?** Controller tests are fast and cover HTTP-level concerns (redirects, status codes, authorization). System tests cover the full browser experience. Prefer controller tests for auth edge cases; system tests for happy-path flows.
- **When to run only fast tests?** For model/controller changes with no UI impact, `bin/rails test` is sufficient. Always run `bin/validate` before submitting.

## Common Pitfalls

- **Forgetting the auth bypass**: System tests do NOT go through the OTP email flow. They use `sign_in_via_browser(user)` which hits `GET /test/sign_in/:user_id`. This route only exists in `Rails.env.test?`. The OTP flow is covered separately in `test/controllers/sessions_controller_test.rb`.
- **Missing Chrome/ChromeDriver**: System tests require Chrome and ChromeDriver. Capybara runs headless at 1400×1400. If Chrome is missing, system tests will fail immediately.
- **Running system tests in CI without a display**: Ensure the CI environment has a headless Chrome available.
- **Fixture vs. created records**: Tests use fixtures. Changing fixture data can break unrelated tests — check `test/fixtures/` before modifying shared records.
