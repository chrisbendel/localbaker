require "test_helper"

class StoresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "owner@example.com")
    sign_in_as(@user)
  end

  test "redirects to new store when user has no store" do
    get store_path
    assert_redirected_to new_store_path
  end

  test "new renders when user has no store" do
    get new_store_path
    assert_response :success
  end

  test "new redirects if user already has a store" do
    Store.create!(name: "Mine", slug: "mine", user: @user)
    get new_store_path
    assert_redirected_to store_path
  end

  test "create creates a store" do
    assert_difference -> { Store.count }, +1 do
      post store_path, params: {
        store: {
          name: "My Store",
          slug: "my-store"
        }
      }
    end
    assert_redirected_to store_path
  end

  test "show renders when store exists" do
    Store.create!(name: "Mine", slug: "mine", user: @user)
    get store_path
    assert_response :success
  end

  test "destroy removes store" do
    Store.create!(name: "Mine", slug: "mine", user: @user)

    assert_difference -> { Store.count }, -1 do
      delete store_path
    end

    assert_redirected_to root_path
  end

  # --- QR plan gate ---

  test "GET qr redirects free user to upgrade page" do
    Store.create!(name: "Mine", slug: "mine", user: @user)
    get qr_store_path
    assert_redirected_to billing_upgrade_path
  end

  test "GET qr renders for pro user" do
    @user.update!(plan: :pro)
    Store.create!(name: "Mine", slug: "mine", user: @user)
    get qr_store_path
    assert_response :success
  end
end
