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

  test "edit renders unless locked" do
    Store.create!(name: "Mine", slug: "mine", user: @user)
    get edit_store_path
    assert_response :success
  end

  test "edit renders even when store has active orders" do
    Store.create!(name: "Mine", slug: "mine", user: @user)

    # Force active_orders? to true
    original = Store.instance_method(:active_orders?)
    Store.define_method(:active_orders?) { true }
    begin
      get edit_store_path
      assert_response :success
    ensure
      # Restore original implementation
      Store.define_method(:active_orders?, original)
    end
  end

  test "update updates store" do
    store = Store.create!(name: "Mine", slug: "mine", user: @user)
    patch store_path, params: {store: {name: "Updated"}}

    assert_redirected_to store_path
    assert_equal "Updated", store.reload.name
  end

  test "destroy removes store" do
    Store.create!(name: "Mine", slug: "mine", user: @user)

    assert_difference -> { Store.count }, -1 do
      delete store_path
    end

    assert_redirected_to dashboard_path
  end
end
