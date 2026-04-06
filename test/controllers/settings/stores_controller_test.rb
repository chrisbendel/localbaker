require "test_helper"

module Settings
  class StoresControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = User.create!(email: "owner@example.com")
      @store = Store.create!(name: "Mine", slug: "mine", user: @user)
      sign_in_as(@user)
    end

    test "show (edit) renders" do
      get settings_store_path
      assert_response :success
    end

    test "update updates store" do
      patch settings_store_path, params: {store: {name: "Updated"}}
      assert_redirected_to settings_store_path
      assert_equal "Updated", @store.reload.name
    end

    test "update handles address" do
      patch settings_store_path, params: {store: {address: "456 Oven Rd, Portland, OR"}}
      assert_redirected_to settings_store_path
      assert_equal "456 Oven Rd, Portland, OR", @store.reload.address
    end

    test "update handles banner removal" do
      # Attach a dummy banner
      @store.banner_image.attach(io: File.open(Rails.root.join("test/fixtures/files/banner.png")), filename: "banner.png", content_type: "image/png")
      assert @store.banner_image.attached?

      patch settings_store_path, params: {store: {remove_banner_image: "1"}}
      assert_redirected_to settings_store_path
      assert_not @store.reload.banner_image.attached?
    end

    test "update rejects invalid facebook URL" do
      patch settings_store_path, params: {store: {facebook_url: "not a url"}}
      assert_response :unprocessable_entity
      refute_equal "not a url", @store.reload.facebook_url
    end

    test "update accepts valid facebook URL" do
      patch settings_store_path, params: {store: {facebook_url: "https://facebook.com/bakery"}}
      assert_redirected_to settings_store_path
      assert_equal "https://facebook.com/bakery", @store.reload.facebook_url
    end

    test "update rejects invalid instagram handle" do
      patch settings_store_path, params: {store: {instagram_handle: "my-bakery"}}
      assert_response :unprocessable_entity
      refute_equal "my-bakery", @store.reload.instagram_handle
    end

    test "update accepts valid instagram handle" do
      patch settings_store_path, params: {store: {instagram_handle: "mybakery"}}
      assert_redirected_to settings_store_path
      assert_equal "mybakery", @store.reload.instagram_handle
    end

    test "update rejects invalid venmo handle" do
      patch settings_store_path, params: {store: {venmo_handle: "my.bakery"}}
      assert_response :unprocessable_entity
      refute_equal "my.bakery", @store.reload.venmo_handle
    end

    test "update accepts valid venmo handle" do
      patch settings_store_path, params: {store: {venmo_handle: "my-bakery"}}
      assert_redirected_to settings_store_path
      assert_equal "my-bakery", @store.reload.venmo_handle
    end

    test "update rejects bio longer than 1000 characters" do
      long_bio = "a" * 1001
      patch settings_store_path, params: {store: {bio: long_bio}}
      assert_response :unprocessable_entity
      refute_equal long_bio, @store.reload.bio
    end

    test "update accepts bio with 1000 characters" do
      bio = "a" * 1000
      patch settings_store_path, params: {store: {bio: bio}}
      assert_redirected_to settings_store_path
      assert_equal bio, @store.reload.bio
    end

    test "update accepts multiple profile fields simultaneously" do
      patch settings_store_path, params: {
        store: {
          name: "Updated Bakery",
          bio: "Fresh baked goods",
          instagram_handle: "mybakery",
          facebook_url: "https://facebook.com/bakery"
        }
      }
      assert_redirected_to settings_store_path
      @store.reload
      assert_equal "Updated Bakery", @store.name
      assert_equal "Fresh baked goods", @store.bio
      assert_equal "mybakery", @store.instagram_handle
      assert_equal "https://facebook.com/bakery", @store.facebook_url
    end

    test "update prevents slug change when store has active orders" do
      # Create a future event with an order
      future_event = @store.events.create!(
        name: "Future Event",
        orders_close_at: 1.day.from_now,
        pickup_at: 2.days.from_now
      )
      future_event.orders.create!(user: User.create!(email: "customer@example.com"))

      # Attempt to change slug
      patch settings_store_path, params: {store: {slug: "new-slug"}}
      assert_response :unprocessable_entity
      assert_equal "mine", @store.reload.slug
    end

    test "update allows slug change when no active orders" do
      # Ensure no active orders
      assert_not @store.active_orders?

      patch settings_store_path, params: {store: {slug: "new-slug"}}
      assert_redirected_to settings_store_path
      assert_equal "new-slug", @store.reload.slug
    end

    test "update clears optional profile fields" do
      @store.update!(
        bio: "Original bio",
        instagram_handle: "mybakery",
        facebook_url: "https://facebook.com/bakery"
      )

      patch settings_store_path, params: {
        store: {
          bio: "",
          instagram_handle: "",
          facebook_url: ""
        }
      }
      assert_redirected_to settings_store_path
      @store.reload
      assert_nil @store.bio
      assert_nil @store.instagram_handle
      assert_nil @store.facebook_url
    end
  end
end
