require "test_helper"

class OrderTest < ActiveSupport::TestCase
  def setup
    @owner = User.create!(email: "owner-#{SecureRandom.hex(4)}@example.com")
    @store = Store.create!(name: "Test Store", slug: "test-store-#{SecureRandom.hex(4)}", user: @owner)
    @event = @store.events.create!(name: "Test Event", orders_close_at: 1.day.from_now, pickup_starts_at: 2.days.from_now, pickup_ends_at: 2.days.from_now + 4.hours)
    @user = User.create!(email: "customer-#{SecureRandom.hex(4)}@example.com")
  end

  test "calculates total_price_cents" do
    order = Order.create!(user: @user, event: @event)
    p1 = @event.event_products.create!(name: "Bread", price: 5, quantity: 100)
    p2 = @event.event_products.create!(name: "Cookie", price: 2, quantity: 100)

    order.order_items.create!(event_product: p1, quantity: 2, unit_price_cents: 500)
    order.order_items.create!(event_product: p2, quantity: 3, unit_price_cents: 200)

    # 2 * 500 + 3 * 200 = 1000 + 600 = 1600
    assert_equal 1600, order.total_price_cents
  end

  test "calculates total_price" do
    order = Order.create!(user: @user, event: @event)
    p1 = @event.event_products.create!(name: "Bread", price: 5, quantity: 100)

    order.order_items.create!(event_product: p1, quantity: 2, unit_price_cents: 500)

    assert_equal 10.0, order.total_price
  end

  test "validates uniqueness of user per event" do
    Order.create!(user: @user, event: @event)
    duplicate_order = Order.new(user: @user, event: @event)

    assert_not duplicate_order.valid?
    assert_includes duplicate_order.errors[:user_id], "has already been taken"
  end
end
