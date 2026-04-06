require "application_system_test_case"

class BakerProfileTest < ApplicationSystemTestCase
  setup do
    @baker = User.create!(email: "baker@example.com")
    @store = @baker.create_store!(
      name: "The Crusty Loaf",
      slug: "crusty-loaf",
      description: "Fresh sourdough."
    )
  end

  test "baker can update profile and payment info" do
    sign_in_via_browser(@baker)
    # 1. Update Bio
    visit settings_profile_path
    fill_in "Baker Bio", with: "Baking bread in my backyard oven since 2020."
    fill_in "Instagram Handle", with: "@crusty_loaf"
    click_on "Save Changes"
    assert_text "Baker profile updated."

    # 2. Update Payments
    visit settings_payments_path
    fill_in "Venmo Handle", with: "@crusty-baker"
    click_on "Save Changes"
    assert_text "Payment options updated."

    # Verify on public profile
    visit storefront_path(@store.slug)

    assert_text "Meet the Baker"
    assert_text "Baking bread in my backyard oven since 2020."
    assert_link "Instagram"
    assert_text "Venmo (@crusty-baker)"

    # Create an event and order to verify payment links in summary
    @event = @store.events.create!(
      name: "Test Bake",
      pickup_at: 2.days.from_now,
      orders_close_at: 1.day.from_now
    )
    @product = @event.event_products.create!(name: "Bread", price_cents: 1000, quantity: 10)
    @event.update!(published_at: Time.current)

    @order = @event.orders.create!(user: @baker)
    @order.order_items.create!(event_product: @product, quantity: 1, unit_price_cents: 1000)

    visit storefront_event_path(@store.slug, @event)
    click_on "Complete Order"

    assert_text "Order confirmed"
    assert_text "Venmo (@crusty-baker)"

    # Check content presence on storefront
    visit storefront_path(@store.slug)
    assert_text "Meet the Baker"
  end
end
