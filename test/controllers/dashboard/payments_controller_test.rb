require "test_helper"

module Dashboard
  class PaymentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = User.create!(email: "owner@example.com")
      @store = Store.create!(name: "Mine", slug: "mine", user: @user)
      sign_in_as(@user)
    end

    test "show handles render" do
      get dashboard_payments_path
      assert_response :success
    end

    test "update handles venmo" do
      patch dashboard_payments_path, params: {store: {venmo_handle: "@newhandle"}}
      assert_redirected_to dashboard_payments_path
      assert_equal "@newhandle", @store.reload.venmo_handle
    end

    test "update handles paypal" do
      patch dashboard_payments_path, params: {store: {paypal_url: "https://paypal.me/new"}}
      assert_redirected_to dashboard_payments_path
      assert_equal "https://paypal.me/new", @store.reload.paypal_url
    end

    test "update rejects invalid venmo handle" do
      patch dashboard_payments_path, params: {store: {venmo_handle: "my.invalid"}}
      assert_response :unprocessable_entity
      refute_equal "my.invalid", @store.reload.venmo_handle
    end

    test "update rejects invalid paypal URL" do
      patch dashboard_payments_path, params: {store: {paypal_url: "not a valid url"}}
      assert_response :unprocessable_entity
      refute_equal "not a valid url", @store.reload.paypal_url
    end

    test "update accepts clearing venmo handle" do
      @store.update!(venmo_handle: "@oldhandle")
      patch dashboard_payments_path, params: {store: {venmo_handle: ""}}
      assert_redirected_to dashboard_payments_path
      assert_nil @store.reload.venmo_handle
    end

    test "update accepts clearing paypal URL" do
      @store.update!(paypal_url: "https://paypal.me/old")
      patch dashboard_payments_path, params: {store: {paypal_url: ""}}
      assert_redirected_to dashboard_payments_path
      assert_nil @store.reload.paypal_url
    end

    test "update accepts valid venmo and paypal together" do
      patch dashboard_payments_path, params: {
        store: {
          venmo_handle: "my-bakery",
          paypal_url: "https://paypal.me/mybakery"
        }
      }
      assert_redirected_to dashboard_payments_path
      @store.reload
      assert_equal "my-bakery", @store.venmo_handle
      assert_equal "https://paypal.me/mybakery", @store.paypal_url
    end
  end
end
