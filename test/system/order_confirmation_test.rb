require "application_system_test_case"

class OrderConfirmationTest < ApplicationSystemTestCase
  setup do
    @baker = User.create!(email: "baker@example.com")
    @store = Store.create!(name: "Test Bakery", slug: "test-bakery", user: @baker, address: "123 Main St")
    @event = @store.events.create!(
      name: "Big Bake",
      orders_close_at: 1.day.from_now,
      pickup_at: 2.days.from_now
    )
    @product = @event.event_products.create!(name: "Sourdough", quantity: 10, price_cents: 1000)
    @event.publish!

    @customer = User.create!(email: "customer@example.com")
  end

  test "full order confirmation flow" do
    sign_in_via_browser(@customer)
    visit storefront_event_path(@store.slug, @event)

    # 1. Add item
    within ".card", text: "Sourdough" do
      click_on "Add to Order"
    end

    assert_text "Added Sourdough"
    assert_button "Complete Order"

    # 2. Confirm order
    click_on "Complete Order"

    assert_text "Order confirmed!"
    assert_selector "aside", text: "Order confirmed"
    assert_selector "aside", text: "Add to Google Calendar"

    # 3. Add another item (should unconfirm)
    within ".card", text: "Sourdough" do
      click_on "Add to Order"
    end

    # Should reset to draft
    assert_text "Added Sourdough"
    assert_selector "aside", text: "Your order"
    assert_button "Complete Order"

    # 4. Edit Order button should unconfirm
    click_on "Complete Order"
    assert_text "Order confirmed!"

    click_on "Edit Order"
    assert_button "Complete Order"
  end
end
