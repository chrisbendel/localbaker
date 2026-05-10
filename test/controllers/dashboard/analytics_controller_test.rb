require "test_helper"

# Negative + positive tests for the Pro gate on Dashboard::AnalyticsController.
# Mirrors the gate enforced by `before_action :require_pro!`.
class Dashboard::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "owner-analytics@example.com")
    @store = Store.create!(user: @user, name: "Test Store", slug: "test-store-#{SecureRandom.hex(4)}")
    sign_in_as(@user)
  end

  test "GET show is blocked for free users with redirect to upgrade" do
    as_free(@user)
    get dashboard_analytics_path
    assert_redirected_to billing_upgrade_path
    follow_redirect!
    assert_select ".alert", /Pro/i
  end

  test "GET show succeeds for pro users" do
    as_pro(@user)
    get dashboard_analytics_path
    assert_response :success
  end
end
