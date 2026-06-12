require "test_helper"

class Dashboard::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @baker = User.create!(email: "baker@example.com")
    @store = Store.create!(user: @baker, name: "Test Bakery", slug: "test-bakery")
    @event = @store.events.create!(
      name: "Bread Pickup",
      description: "Fresh sourdough",
      orders_close_at: 1.day.from_now,
      pickup_starts_at: 2.days.from_now,
      pickup_ends_at: 2.days.from_now + 4.hours
    )
    @customer = User.create!(email: "customer@example.com")
    @order = Order.create!(user: @customer, event: @event)

    sign_in_as(@baker)
  end

  test "marks an order paid and unmarks it" do
    patch dashboard_order_path(@order), params: {order: {paid: "1"}}
    assert @order.reload.paid?

    patch dashboard_order_path(@order), params: {order: {paid: "0"}}
    assert_not @order.reload.paid?
  end

  test "marks an order picked up" do
    patch dashboard_order_path(@order), params: {order: {picked_up: "1"}}
    assert @order.reload.picked_up?
  end

  test "marking paid does not clobber an existing timestamp" do
    original = 2.days.ago.change(usec: 0)
    @order.update!(paid_at: original)

    patch dashboard_order_path(@order), params: {order: {paid: "1"}}
    assert_equal original, @order.reload.paid_at
  end

  test "cannot update an order belonging to another store" do
    other_baker = User.create!(email: "other@example.com")
    other_store = Store.create!(user: other_baker, name: "Other Bakery", slug: "other-bakery")
    other_event = other_store.events.create!(
      name: "Other Pickup",
      description: "Rolls",
      orders_close_at: 1.day.from_now,
      pickup_starts_at: 2.days.from_now,
      pickup_ends_at: 2.days.from_now + 4.hours
    )
    other_order = Order.create!(user: @customer, event: other_event)

    patch dashboard_order_path(other_order), params: {order: {paid: "1"}}

    assert_response :not_found
    assert_not other_order.reload.paid?
  end
end
