require "application_system_test_case"

# Covers the full baker journey:
#   sign in → create store → create event → add products →
#   publish → edit product → delete product → view orders → sign out
class BakerLifecycleTest < ApplicationSystemTestCase
  setup do
    @baker = User.create!(email: "baker@example.com")
  end

  test "full baker lifecycle" do
    # ----------------------------------------------------------------
    # 1. Sign in
    # ----------------------------------------------------------------
    sign_in_via_browser(@baker)
    assert_current_path dashboard_path

    # Empty state is visible
    assert_text "your dashboard"
    assert_text "Create your Store"

    # ----------------------------------------------------------------
    # 2. Create store
    # ----------------------------------------------------------------
    click_on "Create your Store"
    assert_current_path new_store_path

    fill_in "Name", with: "Morning Loaf"
    fill_in "Store URL", with: "morning-loaf"
    fill_in "Description", with: "Fresh bread baked every Saturday morning."
    click_on "Create Store"

    assert_text "Morning Loaf"
    # Header nav now has store shortcuts
    assert_link "Storefront"
    assert_link "Manage"
    # Nudge to create first event
    assert_text "create your first event"

    # ----------------------------------------------------------------
    # 3. Create an event
    # ----------------------------------------------------------------
    click_on "create your first event"
    assert_current_path new_store_event_path

    fill_in "Name", with: "Saturday Bake"
    fill_in "Description", with: "Sourdough and focaccia this week."
    fill_in "Orders close at", with: 5.days.from_now.strftime("%Y-%m-%d")
    fill_in "Pickup date", with: 7.days.from_now.strftime("%Y-%m-%d")
    find("main [type='submit']").click

    assert_text "Event created"
    assert_text "Saturday Bake"
    assert_css ".badge.draft"
    # Publish button hidden until products exist
    assert_no_button "Publish Event"
    # Nudge to add first product
    assert_text "Add your first product"

    # ----------------------------------------------------------------
    # 4. Add first product
    # ----------------------------------------------------------------
    click_on "Add your first product"
    assert_text "Add Product"

    fill_in "Name", with: "Sourdough Loaf"
    fill_in "Quantity", with: "10"
    fill_in "Price ($)", with: "14.00"
    find("main [type='submit']").click

    assert_text "Product added"
    assert_text "Sourdough Loaf"

    # ----------------------------------------------------------------
    # 5. Add second product
    # ----------------------------------------------------------------
    click_on "+ Add Product"
    fill_in "Name", with: "Olive Focaccia"
    fill_in "Quantity", with: "8"
    fill_in "Price ($)", with: "12.00"
    find("main [type='submit']").click

    assert_text "Product added"
    assert_text "Olive Focaccia"

    # Publish button now appears (products exist)
    assert_button "Publish Event"

    # ----------------------------------------------------------------
    # 6. Publish event
    # ----------------------------------------------------------------
    accept_confirm do
      click_on "Publish Event"
    end

    assert_text "Event published"
    assert_no_css ".badge.draft"

    # Orders section is present but empty (prep summary only shows when orders exist)
    assert_text "Orders"
    assert_text "No orders yet"

    # ----------------------------------------------------------------
    # 7. Edit a product
    # ----------------------------------------------------------------
    click_on "Edit", match: :first
    assert_text "Edit Product"

    fill_in "Quantity", with: "12"
    find("main [type='submit']").click

    assert_text "Product updated"

    # Back on event page, updated quantity reflected
    within find("tr", text: "Sourdough Loaf") do
      assert_text "12"
    end

    # ----------------------------------------------------------------
    # 8. Delete a product
    # ----------------------------------------------------------------
    product_row_count_before = all("tbody tr").count

    accept_confirm do
      within find("tr", text: "Olive Focaccia") do
        click_on "Delete"
      end
    end

    assert_text "Product removed"
    assert_no_text "Olive Focaccia"
    assert_equal product_row_count_before - 1, all("tbody tr").count

    # ----------------------------------------------------------------
    # 9. Dashboard shows event card (not table)
    # ----------------------------------------------------------------
    visit dashboard_path

    assert_text "Events"
    assert_css ".card", text: "Saturday Bake"

    # ----------------------------------------------------------------
    # 10. Edit event
    # ----------------------------------------------------------------
    click_on "Saturday Bake"
    click_on "Edit event"
    assert_text "Edit Event"

    fill_in "Name", with: "Saturday Bake (Updated)"
    find("main [type='submit']").click

    assert_text "Event updated"
    assert_text "Saturday Bake (Updated)"

    # ----------------------------------------------------------------
    # 11. Header store nav works from any page
    # ----------------------------------------------------------------
    click_on "Storefront"
    assert_text "Morning Loaf"
    assert_text "Upcoming Bakes"

    click_on "Manage"
    assert_text "Morning Loaf"
    assert_link "View Storefront"

    # ----------------------------------------------------------------
    # 12. Sign out
    # ----------------------------------------------------------------
    click_on "Sign out"
    assert_current_path root_path
    assert_no_link "Sign out"
    assert_link "Sign in"
  end
end
