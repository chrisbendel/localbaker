require "test_helper"

module Settings
  class ProfilesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = User.create!(email: "owner@example.com")
      @store = Store.create!(name: "Mine", slug: "mine", user: @user)
      sign_in_as(@user)
    end

    test "show renders" do
      get settings_profile_path
      assert_response :success
    end

    test "update updates profile" do
      patch settings_profile_path, params: {
        store: {
          bio: "New bio",
          instagram_handle: "@new_handle"
        }
      }
      assert_redirected_to settings_profile_path
      @store.reload
      assert_equal "New bio", @store.bio
      assert_equal "@new_handle", @store.instagram_handle
    end
  end
end
