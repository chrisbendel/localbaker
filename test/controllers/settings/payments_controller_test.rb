require "test_helper"

module Settings
  class PaymentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = User.create!(email: "owner@example.com")
      @store = Store.create!(name: "Mine", slug: "mine", user: @user)
      sign_in_as(@user)
    end

    test "show handles render" do
      get settings_payments_path
      assert_response :success
    end

    test "update handles venmo" do
      patch settings_payments_path, params: { store: { venmo_handle: "@newhandle" } }
      assert_redirected_to settings_payments_path
      assert_equal "@newhandle", @store.reload.venmo_handle
    end

    test "update handles paypal" do
      patch settings_payments_path, params: { store: { paypal_url: "https://paypal.me/new" } }
      assert_redirected_to settings_payments_path
      assert_equal "https://paypal.me/new", @store.reload.paypal_url
    end
  end
end
