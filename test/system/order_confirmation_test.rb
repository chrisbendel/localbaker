require "application_system_test_case"

class OrderConfirmationTest < ApplicationSystemTestCase
  setup do
    @baker = User.create!(email: "baker@example.com")
    @store = Store.create!(name: "Test Bakery", slug: "test-bakery", user: @baker, address: "123 Main St")
    @event = @store.events.create!(
      name: "Big Bake",
      orders_close_at: 1.day.from_now,
      pickup_starts_at: 2.days.from_now + 11.hours,
      pickup_ends_at: 2.days.from_now + 15.hours
    )
    @product = @event.event_products.create!(name: "Sourdough", quantity: 10, price_cents: 1000)
    @event.publish!

    @customer = User.create!(email: "customer@example.com")
  end

  test "full order placement flow" do
    sign_in_via_browser(@customer)
    visit shop_event_path(@store.slug, @event)

    # 1. Place an order via single form
    fill_in "items_#{@product.id}", with: "2"
    fill_in "Note for the baker (optional)", with: "slice please"
    click_on "Place Order"

    assert_text "Order placed"
    assert_selector "aside", text: "Your order"
    assert_selector "aside", text: "Add to Google Calendar"

    # 2. Update the order — change quantity (form is always visible below summary)
    assert_text "Update your order"

    fill_in "items_#{@product.id}", with: "3"
    click_on "Save Changes"

    assert_text "Order updated"
    order = @event.orders.find_by!(user: @customer)
    assert_equal 3, order.order_items.first.quantity

    # 3. Cancel
    accept_confirm do
      click_on "Cancel Order"
    end

    assert_text "Order cancelled"
    assert_no_selector "aside", text: "Your order"
    # Form is back
    assert_button "Place Order"
  end
end
