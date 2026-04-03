require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "profile@example.com")
  end

  test "redirects when not authenticated" do
    get profile_path
    assert_redirected_to new_session_path
  end

  test "renders profile page when signed in" do
    sign_in_as(@user)
    get profile_path
    assert_response :success
    assert_select "title", /Profile/
  end

  test "shows create your store link for user without a store" do
    sign_in_as(@user)
    get profile_path
    assert_select "a[href='#{new_store_path}']", "Create your store"
  end

  test "does not show create your store link for user who already has a store" do
    @user.create_store!(name: "My Bakery", slug: "my-bakery")
    sign_in_as(@user)
    get profile_path
    assert_select "a[href='#{new_store_path}']", false
  end
end
