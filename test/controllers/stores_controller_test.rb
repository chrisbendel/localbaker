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

  test "create stores address when provided" do
    post store_path, params: {
      store: {
        name: "My Store",
        slug: "my-store",
        address: "123 Baker Lane, Portland, OR"
      }
    }
    assert_equal "123 Baker Lane, Portland, OR", Store.last.address
  end

  test "update can save address" do
    Store.create!(name: "Mine", slug: "mine", user: @user)
    patch store_path, params: {store: {address: "456 Oven Rd, Portland, OR"}}
    assert_equal "456 Oven Rd, Portland, OR", @user.store.reload.address
  end

  test "update can clear address" do
    Store.create!(name: "Mine", slug: "mine", user: @user, address: "456 Oven Rd, Portland, OR")
    patch store_path, params: {store: {address: ""}}
    assert_predicate @user.store.reload.address, :blank?
  end

  test "destroy removes store" do
    Store.create!(name: "Mine", slug: "mine", user: @user)

    assert_difference -> { Store.count }, -1 do
      delete store_path
    end

    assert_redirected_to dashboard_path
  end
end
