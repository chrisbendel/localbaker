require "application_system_test_case"

# Covers the full customer journey:
#   sign in → browse storefront → subscribe → open event →
#   add items → adjust quantities → remove item → view dashboard order → sign out
#
# Baker data is seeded directly (baker flow is covered in baker_lifecycle_test.rb).
class CustomerLifecycleTest < ApplicationSystemTestCase
  setup do
    # Seed a published bakery with two products
    baker = User.create!(email: "baker@breadbarn.com")
    @store = Store.create!(name: "The Bread Barn", slug: "bread-barn", user: baker, address: "123 Home Bakery Ln, Portland, OR")
    @event = @store.events.create!(
      name: "Sunday Bake",
      description: "Sourdough and focaccia.",
      orders_close_at: 5.days.from_now,
      pickup_at: 7.days.from_now,
      pickup_address: "The Climbing Gym, 456 Oak Ave, Portland, OR"
    )
    @sourdough = @event.event_products.create!(name: "Sourdough", quantity: 10, price_cents: 1400)
    @focaccia = @event.event_products.create!(name: "Focaccia", quantity: 8, price_cents: 1200)
    @event.publish!

    @customer = User.create!(email: "customer@example.com")
  end

  test "storefront event shows store address as fallback when event has no pickup location" do
    # Temporarily clear the event's pickup address so the store address shows
    @event.update_columns(pickup_address: nil)

    sign_in_via_browser(@customer)
    visit storefront_event_url(@store.slug, @event)

    assert_link "123 Home Bakery Ln, Portland, OR"
    assert_no_text "The Climbing Gym"
  end

  test "storefront event shows no location when neither event nor store has an address" do
    @event.update_columns(pickup_address: nil)
    @store.update_columns(address: nil)

    sign_in_via_browser(@customer)
    visit storefront_event_url(@store.slug, @event)

    # No maps link rendered at all
    assert_no_css "a[href*='google.com/maps']"
  end

  test "full customer lifecycle" do
    # ----------------------------------------------------------------
    # 1. Sign in
    # ----------------------------------------------------------------
    sign_in_via_browser(@customer)
    assert_current_path dashboard_path

    # No orders yet — empty state
    assert_text "dashboard"

    # ----------------------------------------------------------------
    # 2. Browse to storefront
    # ----------------------------------------------------------------
    visit storefront_path(@store.slug)
    assert_text "The Bread Barn"
    assert_text "Sunday Bake"

    # ----------------------------------------------------------------
    # 3. Subscribe to notifications
    # ----------------------------------------------------------------
    click_on "Subscribe"
    assert_text "now following this store"

    # Button flips to Unsubscribe
    assert_button "Unsubscribe"

    # ----------------------------------------------------------------
    # 4. Open the event
    # ----------------------------------------------------------------
    click_on "Sunday Bake"
    assert_text "Products"
    assert_text "Sourdough"
    assert_text "Focaccia"
    assert_text "No items yet"
    assert_no_text "Your order is saved"

    # Event-specific pickup location is shown; store address is not
    assert_link "The Climbing Gym, 456 Oak Ave, Portland, OR"
    assert_no_text "123 Home Bakery Ln"

    # ----------------------------------------------------------------
    # 5. Add sourdough to order
    # ----------------------------------------------------------------
    within find(".card", text: "Sourdough") do
      click_on "Add to Order"
    end

    assert_text "Added Sourdough"

    within "aside" do
      assert_text "Sourdough"
      assert_text "$14.00"
      assert_text "Pickup"
    end

    # ----------------------------------------------------------------
    # 6. Add focaccia to order
    # ----------------------------------------------------------------
    within find(".card", text: "Focaccia") do
      click_on "Add to Order"
    end

    within "aside" do
      assert_text "Sourdough"
      assert_text "Focaccia"
      # Total: $14 + $12 = $26
      assert_text "$26.00"
    end

    # ----------------------------------------------------------------
    # 7. Add sourdough again to bump quantity to 2
    # ----------------------------------------------------------------
    within find(".card", text: "Sourdough") do
      click_on "Add to Order"
    end

    assert_text "Added Sourdough"

    within "aside" do
      # Total: $14*2 + $12 = $40
      assert_text "$40.00"
    end

    # ----------------------------------------------------------------
    # 8. Remove sourdough via × button
    # ----------------------------------------------------------------
    accept_confirm do
      within "aside" do
        find("button[aria-label='Remove Sourdough']").click
      end
    end

    assert_text "Removed Sourdough"

    within "aside" do
      assert_no_text "Sourdough"
      assert_text "Focaccia"
      assert_text "$12.00"
    end

    # ----------------------------------------------------------------
    # 9. Add sourdough back so order has both items again
    # ----------------------------------------------------------------
    within find(".card", text: "Sourdough") do
      click_on "Add to Order"
    end

    within "aside" do
      assert_text "Sourdough"
      assert_text "Focaccia"
      assert_text "$26.00"
    end

    # ----------------------------------------------------------------
    # 11. Dashboard shows order cards (not a table)
    # ----------------------------------------------------------------
    visit dashboard_path

    assert_text "Your Orders"
    assert_css ".card", text: "The Bread Barn"

    within find(".card", text: "The Bread Barn") do
      assert_text "Sunday Bake"
      assert_text "$26.00"
    end

    # Clicking the order card goes to the storefront event
    find(".card", text: "The Bread Barn").click
    assert_text "Products"
    assert_text "Your order"

    # ----------------------------------------------------------------
    # 12. Unsubscribe via the storefront subscribe toggle
    # ----------------------------------------------------------------
    visit storefront_path(@store.slug)
    click_on "Unsubscribe"
    assert_text "no longer following this store"
    assert_button "Subscribe"

    # ----------------------------------------------------------------
    # 13. Sign out
    # ----------------------------------------------------------------
    visit profile_path
    click_on "Sign out"
    assert_current_path root_path
    assert_no_link "Sign out"
  end
end
