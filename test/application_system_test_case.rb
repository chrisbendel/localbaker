require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  # Capybara starts its own Puma instance (ignores config/puma.rb).
  # 1 thread ensures it always uses the same DB connection as the test thread,
  # which is required for transactional tests to work with system tests.
  Capybara.server = :puma, {threads: "1:1"}

  # Signs in via a test-only POST endpoint that bypasses OTP entirely.
  # The email/OTP flow is covered by SessionsController unit tests.
  # Using Capybara's built-in session-aware form submission via visit+form.
  def sign_in_via_browser(user)
    visit test_sign_in_path(user.id)
    visit dashboard_path
  end
end
