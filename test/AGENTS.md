# Test Directory — Testing Strategy

## Agent Instructions

**Do not run tests yourself.** Ask the user to run `bin/validate` and share the results. Tests (especially system tests) are slow and require a browser environment.

> See `.agent/skills/testing.md` for test commands.

## Test Structure

| Directory | Type | Speed |
|---|---|---|
| `test/models/` | Unit | Fast |
| `test/controllers/` | Integration | Fast |
| `test/mailers/` | Mailer | Fast |
| `test/system/` | Browser (Capybara + Selenium) | Slow |

## Auth Helpers

### System tests — `sign_in_via_browser(user)`

System tests bypass the OTP email flow using a test-only endpoint:

- Route: `GET /test/sign_in/:user_id` (only registered when `Rails.env.test?`)
- Controller: `app/controllers/test/auth_controller.rb`
- Helper: `sign_in_via_browser(user)` in `test/application_system_test_case.rb`

Do not attempt to drive the OTP email flow in system tests — use this helper instead.

### Controller/integration tests — `sign_in_as(user)`

`test/test_helper.rb` provides `sign_in_as(user)`. This goes through the full OTP flow by reading from `ActionMailer::Base.deliveries` — it validates the real auth path.

## System Tests

| File | What it covers |
|---|---|
| `baker_lifecycle_test.rb` | Full baker journey: sign in → create store → create event → add products → publish → edit/delete → sign out |
| `customer_lifecycle_test.rb` | Full customer journey: sign in → browse shop → subscribe → add/adjust/remove order items → dashboard → unsubscribe → sign out |
| `onboarding_checklist_test.rb` | Checklist card shows, completes, and dismisses for new bakers |
| `recurring_events_test.rb` | Publishing a weekly-repeat event spawns the next draft |
