require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  def setup
    @owner = User.create!(email: "owner-#{SecureRandom.hex(4)}@example.com")
    @store = Store.create!(name: "Test Store", slug: "test-store-#{SecureRandom.hex(4)}", user: @owner)
    @event = @store.events.create!(name: "Test Event", orders_close_at: 1.day.from_now, pickup_starts_at: 2.days.from_now, pickup_ends_at: 2.days.from_now + 4.hours)
    @event_product = @event.event_products.create!(name: "Sourdough", price: 10, quantity: 100)

    @customer = User.create!(email: "customer-#{SecureRandom.hex(4)}@example.com")
    @order = Order.create!(user: @customer, event: @event)
  end

  test "sets unit_price_cents from event_product on creation" do
    order_item = @order.order_items.build(event_product: @event_product, quantity: 1)
    order_item.save!

    assert_equal 1000, order_item.unit_price_cents
  end

  test "validates quantity is greater than 0" do
    order_item = @order.order_items.build(event_product: @event_product, quantity: 0)
    assert_not order_item.valid?
    assert_includes order_item.errors[:quantity], "must be greater than 0"
  end

  test "validates quantity is less than or equal to 1000" do
    order_item = @order.order_items.build(event_product: @event_product, quantity: 1001)
    assert_not order_item.valid?
    assert_includes order_item.errors[:quantity], "must be less than or equal to 1000"
  end
end
