require "test_helper"

module Stores
  class ProfilesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = User.create!(email: "owner@example.com")
      @store = Store.create!(name: "Mine", slug: "mine", user: @user)
      sign_in_as(@user)
    end

    test "show renders" do
      get store_profile_path
      assert_response :success
    end

    test "update updates profile" do
      patch store_profile_path, params: {
        store: {
          bio: "New bio",
          instagram_handle: "@new_handle"
        }
      }
      assert_redirected_to store_profile_path
      @store.reload
      assert_equal "New bio", @store.bio
      assert_equal "@new_handle", @store.instagram_handle
    end

    test "update accepts valid facebook URL" do
      patch store_profile_path, params: {store: {facebook_url: "https://facebook.com/bakery"}}
      assert_redirected_to store_profile_path
      assert_equal "https://facebook.com/bakery", @store.reload.facebook_url
    end

    test "update rejects invalid facebook URL" do
      patch store_profile_path, params: {store: {facebook_url: "not a url"}}
      assert_response :unprocessable_entity
      refute_equal "not a url", @store.reload.facebook_url
    end

    test "update accepts valid website URL" do
      patch store_profile_path, params: {store: {website_url: "https://mybakery.com"}}
      assert_redirected_to store_profile_path
      assert_equal "https://mybakery.com", @store.reload.website_url
    end

    test "update rejects invalid website URL" do
      patch store_profile_path, params: {store: {website_url: "not a valid url"}}
      assert_response :unprocessable_entity
      refute_equal "not a valid url", @store.reload.website_url
    end

    test "update rejects invalid instagram handle" do
      patch store_profile_path, params: {store: {instagram_handle: "my-invalid-handle"}}
      assert_response :unprocessable_entity
      refute_equal "my-invalid-handle", @store.reload.instagram_handle
    end

    test "update rejects bio longer than 1000 characters" do
      long_bio = "a" * 1001
      patch store_profile_path, params: {store: {bio: long_bio}}
      assert_response :unprocessable_entity
      refute_equal long_bio, @store.reload.bio
    end

    test "update accepts bio with maximum length" do
      max_bio = "a" * 1000
      patch store_profile_path, params: {store: {bio: max_bio}}
      assert_redirected_to store_profile_path
      assert_equal max_bio, @store.reload.bio
    end

    test "update accepts clearing profile fields" do
      @store.update!(
        bio: "Original bio",
        instagram_handle: "original_handle",
        facebook_url: "https://facebook.com/original",
        website_url: "https://original.com"
      )

      patch store_profile_path, params: {
        store: {
          bio: "",
          instagram_handle: "",
          facebook_url: "",
          website_url: ""
        }
      }
      assert_redirected_to store_profile_path
      @store.reload
      assert_nil @store.bio
      assert_nil @store.instagram_handle
      assert_nil @store.facebook_url
      assert_nil @store.website_url
    end

    test "update accepts all profile fields together" do
      patch store_profile_path, params: {
        store: {
          bio: "Fresh baked goods daily",
          instagram_handle: "mybakery",
          facebook_url: "https://facebook.com/mybakery",
          website_url: "https://mybakery.com"
        }
      }
      assert_redirected_to store_profile_path
      @store.reload
      assert_equal "Fresh baked goods daily", @store.bio
      assert_equal "mybakery", @store.instagram_handle
      assert_equal "https://facebook.com/mybakery", @store.facebook_url
      assert_equal "https://mybakery.com", @store.website_url
    end

    test "update accepts instagram handle with leading @" do
      patch store_profile_path, params: {store: {instagram_handle: "@mybakery"}}
      assert_redirected_to store_profile_path
      assert_equal "@mybakery", @store.reload.instagram_handle
    end

    test "update accepts instagram handle with dots" do
      patch store_profile_path, params: {store: {instagram_handle: "my.bakery.co"}}
      assert_redirected_to store_profile_path
      assert_equal "my.bakery.co", @store.reload.instagram_handle
    end

    test "update handles photo upload" do
      photo = fixture_file_upload("banner.png", "image/png")
      patch store_profile_path, params: {store: {photo: photo}}
      assert_redirected_to store_profile_path
      assert @store.reload.photo.attached?
    end

    test "update handles photo removal" do
      @store.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/banner.png")), filename: "banner.png", content_type: "image/png")
      assert @store.photo.attached?

      patch store_profile_path, params: {store: {remove_photo: "1"}}
      assert_redirected_to store_profile_path
    end
  end
end
