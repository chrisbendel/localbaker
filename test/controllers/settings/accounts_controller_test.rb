require "test_helper"

module Settings
  class AccountsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = User.create!(email: "owner@example.com", name: "Original Name")
      sign_in_as(@user)
    end

    test "show renders" do
      get settings_account_path
      assert_response :success
    end

    test "update updates account name but not email" do
      patch settings_account_path, params: {
        user: {
          name: "New Name",
          email: "new@example.com" # Should be ignored
        }
      }
      assert_redirected_to settings_account_path
      @user.reload
      assert_equal "New Name", @user.name
      assert_equal "owner@example.com", @user.email
    end
  end
end
