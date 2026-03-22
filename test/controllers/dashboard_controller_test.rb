require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "test@example.com")
  end

  test "redirects when not authenticated" do
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "renders dashboard when signed in" do
    sign_in_as(@user)
    get dashboard_path
    assert_response :success
    assert_select "title", /Dashboard/
  end

  test "renders orders when user has orders" do
    store = Store.create!(user: User.create!(email: "store@example.com"), name: "Bakery", slug: "bakery")
    event = store.events.create!(name: "Weekly Bake", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)
    product = event.event_products.create!(name: "Sourdough", price_cents: 1000, quantity: 10)

    order = @user.orders.create!(event: event)
    order.order_items.create!(event_product: product, quantity: 1)

    sign_in_as(@user)
    get dashboard_path

    assert_response :success
    assert_select "h3", "Your Orders"
    assert_select ".card", /Bakery/
    assert_select ".card", /Weekly Bake/
  end
end
