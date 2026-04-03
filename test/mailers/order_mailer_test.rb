require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  test "confirmation_email" do
    baker = User.create!(email: "baker@example.com")
    store = Store.create!(name: "Test Bakery", slug: "test-bakery", user: baker, address: "123 Main St")
    event = store.events.create!(name: "Big Bake", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)
    customer = User.create!(email: "customer@example.com")
    order = event.orders.create!(user: customer, confirmed_at: Time.current)

    mail = OrderMailer.with(order: order).confirmation_email

    assert_equal "Order confirmed: Big Bake — Test Bakery", mail.subject
    assert_equal [customer.email], mail.to
    assert_match "Your order for Test Bakery has been confirmed!", mail.body.encoded
  end
end
