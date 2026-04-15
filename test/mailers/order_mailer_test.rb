require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  setup do
    @baker = User.create!(email: "baker@example.com")
    @store = Store.create!(name: "Test Bakery", slug: "test-bakery", user: @baker, address: "123 Main St")
    @event = @store.events.create!(
      name: "Big Bake",
      orders_close_at: 1.day.from_now,
      pickup_starts_at: 2.days.from_now,
      pickup_ends_at: 2.days.from_now + 4.hours
    )
    @product = @event.event_products.create!(name: "Sourdough", quantity: 10, price_cents: 1200)
    @customer = User.create!(email: "customer@example.com")
    @order = @event.orders.create!(user: @customer, confirmed_at: Time.current)
    @order.order_items.create!(event_product: @product, quantity: 2)
  end

  test "confirmation_email sends to customer with itemized summary" do
    mail = OrderMailer.with(order: @order).confirmation_email

    assert_equal "Order confirmed: Big Bake — Test Bakery", mail.subject
    assert_equal [@customer.email], mail.to
    assert_match "Your order for Test Bakery has been confirmed!", mail.body.encoded
    assert_match "Sourdough", mail.body.encoded
    assert_match "2", mail.body.encoded
  end

  test "pickup_reminder sends to customer with order summary and pickup time" do
    mail = OrderMailer.with(order: @order).pickup_reminder

    assert_equal "Pickup reminder: Big Bake tomorrow — Test Bakery", mail.subject
    assert_equal [@customer.email], mail.to
    assert_match "pickup from Test Bakery is tomorrow", mail.body.encoded
    assert_match "Sourdough", mail.body.encoded
    assert_match "2", mail.body.encoded
  end
end
