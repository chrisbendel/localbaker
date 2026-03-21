require "test_helper"

class EventProductTest < ActiveSupport::TestCase
  def setup
    @owner = User.create!(email: "owner-#{SecureRandom.hex(4)}@example.com")
    @store = Store.create!(name: "Test Store", slug: "test-store-#{SecureRandom.hex(4)}", user: @owner)
    @event = @store.events.create!(name: "Test Event", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)
  end

  test "sets price cents from price" do
    product = EventProduct.new(price: "10.50")
    assert_equal 1050, product.price_cents
    assert_equal 10.5, product.price
  end

  test "handles nil price" do
    product = EventProduct.new(price: nil)
    assert_nil product.price_cents
    assert_nil product.price
  end

  test "handles integer price" do
    product = EventProduct.new(price: 15)
    assert_equal 1500, product.price_cents
    assert_equal 15.0, product.price
  end

  test "formats price" do
    product = EventProduct.new(price: 15.5)
    assert_equal "$15.50", product.price_formatted
  end

  test "calculates sold, remaining and availability" do
    product = @event.event_products.create!(name: "Bread", price: 10, quantity: 10)
    customer = User.create!(email: "customer-#{SecureRandom.hex(4)}@example.com")
    # Sell 3 items
    order = Order.create!(user: customer, event: @event)
    order.order_items.create!(event_product: product, quantity: 3, unit_price_cents: 1000)

    assert_equal 3, product.sold
    assert_equal 7, product.remaining
    assert product.available?

    # Sell remaining 7 items
    order2 = Order.create!(user: User.create!(email: "customer2-#{SecureRandom.hex(4)}@example.com"), event: @event)
    order2.order_items.create!(event_product: product, quantity: 7, unit_price_cents: 1000)

    assert_equal 10, product.sold
    assert_equal 0, product.remaining
    assert_not product.available?
  end
end
