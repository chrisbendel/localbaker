require "test_helper"

class StoreNotificationTest < ActiveSupport::TestCase
  setup do
    @baker = User.create!(email: "baker@example.com")
    @store = Store.create!(user: @baker, name: "Test Bakery", slug: "test-bakery")
  end

  test "redeeming a token creates the user and subscription" do
    token = StoreNotification.generate_confirmation_token(email: "new@example.com", store: @store)

    notification = StoreNotification.redeem_confirmation_token(token)

    assert notification.persisted?
    assert_equal @store, notification.store
    assert_equal "new@example.com", notification.user.email
  end

  test "redeeming reuses an existing user and is idempotent" do
    user = User.create!(email: "existing@example.com")
    token = StoreNotification.generate_confirmation_token(email: "existing@example.com", store: @store)

    first = StoreNotification.redeem_confirmation_token(token)
    second = StoreNotification.redeem_confirmation_token(token)

    assert_equal user, first.user
    assert_equal first, second
    assert_equal 1, user.store_notifications.where(store: @store).count
  end

  test "tampered token redeems to nil" do
    token = StoreNotification.generate_confirmation_token(email: "new@example.com", store: @store)
    assert_nil StoreNotification.redeem_confirmation_token(token + "x")
    assert_nil StoreNotification.redeem_confirmation_token("garbage")
  end

  test "token expires after 7 days" do
    token = StoreNotification.generate_confirmation_token(email: "new@example.com", store: @store)
    travel 8.days do
      assert_nil StoreNotification.redeem_confirmation_token(token)
    end
  end
end
