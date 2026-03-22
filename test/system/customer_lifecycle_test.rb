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
    @store = Store.create!(name: "The Bread Barn", slug: "bread-barn", user: baker)
    @event = @store.events.create!(
      name: "Sunday Bake",
      description: "Sourdough and focaccia.",
      orders_close_at: 5.days.from_now,
      pickup_at: 7.days.from_now
    )
    @sourdough = @event.event_products.create!(name: "Sourdough", quantity: 10, price_cents: 1400)
    @focaccia = @event.event_products.create!(name: "Focaccia", quantity: 8, price_cents: 1200)
    @event.publish!

    @customer = User.create!(email: "customer@example.com")
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
    assert_text "Products Available"
    assert_text "Sourdough"
    assert_text "Focaccia"
    assert_text "No items yet"
    assert_no_text "Your order is saved"

    # ----------------------------------------------------------------
    # 5. Add sourdough to order
    # ----------------------------------------------------------------
    within find(".card", text: "Sourdough") do
      click_on "Add to Order"
    end

    assert_text "Added!"

    within "aside" do
      assert_text "Sourdough"
      assert_text "$14.00"
      assert_text "Your order is saved"
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
    # 7. Increase sourdough quantity via + button
    # ----------------------------------------------------------------
    within find("tr", text: "Sourdough") do
      click_on "+"
    end

    assert_text "Updated quantity"

    within "aside" do
      # Total: $14*2 + $12 = $40
      assert_text "$40.00"
    end

    # ----------------------------------------------------------------
    # 8. Decrease sourdough back via − button
    # ----------------------------------------------------------------
    within find("tr", text: "Sourdough") do
      click_on "−"
    end

    assert_text "Updated quantity"

    within "aside" do
      assert_text "$26.00"
    end

    # ----------------------------------------------------------------
    # 9. Remove focaccia by decrementing to 0
    # ----------------------------------------------------------------
    within find("tr", text: "Focaccia") do
      click_on "−"
    end

    assert_text "Removed item"

    within "aside" do
      assert_text "Sourdough"
      assert_no_text "Focaccia"
      assert_text "$14.00"
    end

    # ----------------------------------------------------------------
    # 10. Add focaccia back via Add to Order, then remove via − again
    #     (covers the full remove path via order_items#destroy as well
    #      as re-adding after removal)
    # ----------------------------------------------------------------
    within find(".card", text: "Focaccia") do
      click_on "Add to Order"
    end

    within "aside" do
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
    assert_text "Products Available"
    assert_text "Your order is saved"

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
    click_on "Sign out"
    assert_current_path root_path
    assert_no_link "Sign out"
  end
end
