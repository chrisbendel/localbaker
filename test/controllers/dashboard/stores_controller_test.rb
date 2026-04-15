require "test_helper"

module Dashboard
  class StoresControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = User.create!(email: "owner@example.com")
      sign_in_as(@user)
    end

    test "new renders when user has no store" do
      get new_dashboard_store_path
      assert_response :success
    end

    test "new redirects if user already has a store" do
      Store.create!(name: "Mine", slug: "mine", user: @user)
      get new_dashboard_store_path
      assert_redirected_to dashboard_path
    end

    test "create creates a store" do
      assert_difference -> { Store.count }, +1 do
        post dashboard_store_path, params: {
          store: {
            name: "My Store",
            slug: "my-store"
          }
        }
      end
      assert_redirected_to dashboard_path
    end

    test "show (edit) renders for pro user" do
      Store.create!(name: "Mine", slug: "mine", user: @user)
      get dashboard_store_path
      assert_response :success
    end

    test "update updates store" do
      store = Store.create!(name: "Mine", slug: "mine", user: @user)
      patch dashboard_store_path, params: {store: {name: "Updated"}}
      assert_redirected_to dashboard_store_path
      assert_equal "Updated", store.reload.name
    end

    test "update handles address" do
      store = Store.create!(name: "Mine", slug: "mine", user: @user)
      patch dashboard_store_path, params: {store: {address: "456 Oven Rd, Portland, OR"}}
      assert_redirected_to dashboard_store_path
      assert_equal "456 Oven Rd, Portland, OR", store.reload.address
    end

    test "update handles banner removal" do
      store = Store.create!(name: "Mine", slug: "mine", user: @user)
      # Attach a dummy banner
      store.banner_image.attach(io: File.open(Rails.root.join("test/fixtures/files/banner.jpeg")), filename: "banner.jpeg", content_type: "image/jpeg")
      assert store.banner_image.attached?

      patch dashboard_store_path, params: {store: {remove_banner_image: "1"}}
      assert_redirected_to dashboard_store_path
      assert_not store.reload.banner_image.attached?
    end

    test "destroy removes store" do
      Store.create!(name: "Mine", slug: "mine", user: @user)

      assert_difference -> { Store.count }, -1 do
        delete dashboard_store_path
      end

      assert_redirected_to root_path
    end

    # --- QR Poster ---

    test "GET qr renders for any user" do
      Store.create!(name: "Mine", slug: "mine", user: @user)
      get qr_dashboard_store_path
      assert_response :success
    end
  end
end
