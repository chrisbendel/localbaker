require "test_helper"

module Stores
  class StoresControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = User.create!(email: "owner@example.com")
      @store = Store.create!(name: "Mine", slug: "mine", user: @user)
      sign_in_as(@user)
    end

    test "show (edit) renders" do
      get store_settings_path
      assert_response :success
    end

    test "update updates store" do
      patch store_settings_path, params: {store: {name: "Updated"}}
      assert_redirected_to store_settings_path
      assert_equal "Updated", @store.reload.name
    end

    test "update handles address" do
      patch store_settings_path, params: {store: {address: "456 Oven Rd, Portland, OR"}}
      assert_redirected_to store_settings_path
      assert_equal "456 Oven Rd, Portland, OR", @store.reload.address
    end

    test "update handles banner removal" do
      # Attach a dummy banner
      @store.banner_image.attach(io: File.open(Rails.root.join("test/fixtures/files/banner.jpeg")), filename: "banner.jpeg", content_type: "image/jpeg")
      assert @store.banner_image.attached?

      patch store_settings_path, params: {store: {remove_banner_image: "1"}}
      assert_redirected_to store_settings_path
      assert_not @store.reload.banner_image.attached?
    end

    test "update prevents slug change when store has active orders" do
      # Create a future event with an order
      future_event = @store.events.create!(
        name: "Future Event",
        orders_close_at: 1.day.from_now,
        pickup_starts_at: 2.days.from_now,
        pickup_ends_at: 2.days.from_now + 4.hours
      )
      future_event.orders.create!(user: User.create!(email: "customer@example.com"))

      # Attempt to change slug
      patch store_settings_path, params: {store: {slug: "new-slug"}}
      assert_response :unprocessable_entity
      assert_equal "mine", @store.reload.slug
    end

    test "update allows slug change when no active orders" do
      # Ensure no active orders
      assert_not @store.active_orders?

      patch store_settings_path, params: {store: {slug: "new-slug"}}
      assert_redirected_to store_settings_path
      assert_equal "new-slug", @store.reload.slug
    end
  end
end
