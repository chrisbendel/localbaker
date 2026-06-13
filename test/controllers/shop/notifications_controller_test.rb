require "test_helper"

class Shop::NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActiveJob::Base.queue_adapter = :test
    @baker = User.create!(email: "baker@example.com")
    @store = Store.create!(user: @baker, name: "Test Bakery", slug: "test-bakery")
  end

  test "logged-out subscribe sends a confirmation email and writes nothing" do
    assert_no_difference ["User.count", "StoreNotification.count"] do
      assert_enqueued_emails 1 do
        post shop_notification_path(@store.slug), params: {email: " Visitor@Example.com "}
      end
    end
    assert_redirected_to shop_path(@store.slug)
  end

  test "invalid email re-renders the form without sending" do
    assert_no_enqueued_emails do
      post shop_notification_path(@store.slug), params: {email: "not-an-email"}
    end
    assert_response :unprocessable_entity
  end

  test "confirm link creates user and subscription and signs the user in" do
    token = StoreNotification.generate_confirmation_token(email: "visitor@example.com", store: @store)

    assert_difference ["User.count", "StoreNotification.count"], 1 do
      get confirm_shop_notification_path(@store.slug, token: token)
    end

    user = User.find_by(email: "visitor@example.com")
    assert user.store_notifications.exists?(store: @store)
    assert_redirected_to shop_path(@store.slug)

    # Session exists: an authenticated-only page now renders
    get settings_notifications_path
    assert_response :success
  end

  test "confirm is idempotent — clicking twice creates one subscription" do
    token = StoreNotification.generate_confirmation_token(email: "visitor@example.com", store: @store)

    get confirm_shop_notification_path(@store.slug, token: token)
    assert_no_difference ["User.count", "StoreNotification.count"] do
      get confirm_shop_notification_path(@store.slug, token: token)
    end
    assert_redirected_to shop_path(@store.slug)
  end

  test "garbage confirm token redirects to subscribe page with alert" do
    assert_no_difference ["User.count", "StoreNotification.count"] do
      get confirm_shop_notification_path(@store.slug, token: "garbage")
    end
    assert_redirected_to new_shop_notification_path(@store.slug)
  end

  test "logged-in subscribe creates the subscription directly" do
    user = User.create!(email: "customer@example.com")
    sign_in_as(user)

    assert_difference "StoreNotification.count", 1 do
      post shop_notification_path(@store.slug)
    end
    assert user.store_notifications.exists?(store: @store)
  end

  test "subscribe page redirects signed-in users to the store" do
    user = User.create!(email: "customer@example.com")
    sign_in_as(user)

    get new_shop_notification_path(@store.slug)
    assert_redirected_to shop_path(@store.slug)
  end
end
