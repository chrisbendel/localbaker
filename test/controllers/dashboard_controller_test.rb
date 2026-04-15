require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "owner@example.com")
    sign_in_as(@user)
  end

  test "redirects to new store when user has no store" do
    get dashboard_path
    assert_redirected_to new_dashboard_store_path
  end

  test "GET show renders for user with store" do
    Store.create!(name: "Mine", slug: "mine", user: @user)
    get dashboard_path
    assert_response :success
  end
end
