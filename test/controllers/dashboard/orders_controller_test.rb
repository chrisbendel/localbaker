require "test_helper"

class Dashboard::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "owner@example.com")
    @store = Store.create!(user: @user, name: "Test Store", slug: "test-store-#{SecureRandom.hex(4)}")
    @event = @store.events.create!(
      name: "Bread Pickup",
      orders_close_at: 1.day.from_now,
      pickup_starts_at: 2.days.from_now,
      pickup_ends_at: 2.days.from_now + 4.hours
    )
    @product = @event.event_products.create!(name: "Sourdough", price_cents: 1000, quantity: 5)

    sign_in_as(@user)
  end

  test "GET export returns CSV header for store with no orders" do
    get export_dashboard_orders_path
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body.lines.first, "order_date"
  end

  test "GET export returns store-wide orders including ones with notes" do
    customer = User.create!(email: "buyer@example.com")
    order = @event.orders.create!(user: customer, notes: "slice please")
    order.order_items.create!(event_product: @product, quantity: 1, unit_price_cents: 1000)
    order.confirm!

    get export_dashboard_orders_path

    assert_response :success
    assert_includes response.body, "buyer@example.com"
    assert_includes response.body, "1x Sourdough"
    assert_includes response.body, "slice please"
  end

  test "GET export filename uses store slug" do
    get export_dashboard_orders_path
    assert_match(/orders-#{@store.slug}-/, response.headers["Content-Disposition"])
  end
end
