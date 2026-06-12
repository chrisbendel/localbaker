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

    test "set_cover_photo updates the cover" do
      store = Store.create!(name: "Mine", slug: "mine", user: @user)
      store.gallery_photos.attach(fixture_file_upload("bread.jpeg", "image/jpeg"))
      store.gallery_photos.attach(fixture_file_upload("banner.jpeg", "image/jpeg"))
      second = store.gallery_photos.last

      patch cover_photo_dashboard_store_path(photo_id: second.id)

      assert_redirected_to dashboard_store_path
      assert_equal second, store.reload.cover_photo
    end

    test "photo actions cannot touch another store's photos" do
      Store.create!(name: "Mine", slug: "mine", user: @user)
      other = Store.create!(name: "Other", slug: "other", user: User.create!(email: "other@example.com"))
      other.gallery_photos.attach(fixture_file_upload("bread.jpeg", "image/jpeg"))
      foreign = other.gallery_photos.first

      delete photo_dashboard_store_path(photo_id: foreign.id)

      assert_response :not_found
      assert_equal 1, other.reload.gallery_photos.count
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

    # --- Photos ---

    test "add_photos appends without replacing existing ones" do
      store = Store.create!(name: "Mine", slug: "mine", user: @user)
      store.gallery_photos.attach(fixture_file_upload("bread.jpeg", "image/jpeg"))

      post photos_dashboard_store_path, params: {
        gallery_photos: [fixture_file_upload("banner.jpeg", "image/jpeg")]
      }

      assert_redirected_to dashboard_store_path
      assert_equal 2, store.reload.gallery_photos.count
    end

    test "add_photos rejects more than the photo limit" do
      store = Store.create!(name: "Mine", slug: "mine", user: @user)
      Store::GALLERY_PHOTO_LIMIT.times do
        store.gallery_photos.attach(fixture_file_upload("bread.jpeg", "image/jpeg"))
      end

      post photos_dashboard_store_path, params: {
        gallery_photos: [fixture_file_upload("banner.jpeg", "image/jpeg")]
      }

      assert_redirected_to dashboard_store_path
      assert_equal Store::GALLERY_PHOTO_LIMIT, store.reload.gallery_photos.count
    end

    test "remove_photo purges a single photo" do
      store = Store.create!(name: "Mine", slug: "mine", user: @user)
      store.gallery_photos.attach(fixture_file_upload("bread.jpeg", "image/jpeg"))
      photo = store.gallery_photos.first

      delete photo_dashboard_store_path(photo_id: photo.id)

      assert_redirected_to dashboard_store_path
      assert_equal 0, store.reload.gallery_photos.count
    end
  end
end
