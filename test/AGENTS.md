# Testing Rules

**Agents: do not run tests.** Ask the user to run `bin/validate` and share results — system tests are slow and need a browser environment.

## Auth helpers (never drive the OTP email flow manually)

- **System tests**: `sign_in_via_browser(user)` — uses the test-only route `GET /test/sign_in/:user_id` (registered only in test env).
- **Integration tests**: `sign_in_as(user)` in `test/test_helper.rb` — exercises the real OTP path by reading `ActionMailer::Base.deliveries`.

Favor integration/system tests over heavily-mocked unit tests. Partials are tested implicitly via system tests.
