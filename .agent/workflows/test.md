---
description: how to run tests in the application
---
# Testing Workflow

## Test Commands

1. **Unit + integration only** (fast, no browser):
// turbo
```bash
bin/rails test
```

2. **System tests only** (Capybara + headless Chrome):
// turbo
```bash
bin/rails test:system
```

3. **Everything** (recommended before merging):
// turbo
```bash
bin/rails test:all
```

4. Run a specific directory:
```bash
bin/rails test test/models test/controllers
```

5. Run a single file:
```bash
bin/rails test test/system/baker_lifecycle_test.rb
```

6. Run a single test by line number:
```bash
bin/rails test test/system/baker_lifecycle_test.rb:11
```

## Test Structure

| Directory | Type | Speed |
|---|---|---|
| `test/models/` | Unit | Fast |
| `test/controllers/` | Integration | Fast |
| `test/mailers/` | Mailer | Fast |
| `test/system/` | Browser (Capybara + Selenium) | Slow |

## System Tests

System tests live in `test/system/` and cover full user lifecycles:

- `baker_lifecycle_test.rb` — sign in → create store → create event → add products → publish → edit/delete → sign out
- `customer_lifecycle_test.rb` — sign in → browse storefront → subscribe → add/adjust/remove order items → dashboard → unsubscribe → sign out

### Test-Only Auth Bypass

System tests authenticate via a test-only GET endpoint instead of the full OTP email flow (which is covered by controller tests):

- Route: `GET /test/sign_in/:user_id` (only available in `Rails.env.test?`)
- Controller: `app/controllers/test/auth_controller.rb`
- Helper: `sign_in_via_browser(user)` in `test/application_system_test_case.rb`

> [!NOTE]
> System tests require Chrome and ChromeDriver. Capybara is configured to run headless at 1400×1400.
