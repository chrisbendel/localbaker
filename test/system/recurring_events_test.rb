require "application_system_test_case"

class RecurringEventsTest < ApplicationSystemTestCase
  setup do
    @baker = User.create!(email: "baker@example.com")
    @store = Store.create!(user: @baker, name: "The Crusty Loaf", slug: "crusty-loaf")
    sign_in_via_browser(@baker)
  end

  test "publishing an event with weekly repeat spawns next draft" do
    visit store_path

    click_on "New Event"
    fill_in "Name", with: "Weekly Sourdough"

    # Use execute_script to set the value directly
    execute_script("document.getElementById('event_orders_close_at').value = '2026-03-30'")
    execute_script("document.getElementById('event_pickup_at').value = '2026-04-01'")

    select "Weekly", from: "Repeat cadence"
    click_on "Create Event"

    click_on "Add your first product"
    fill_in "Name", with: "Loaf"
    fill_in "Quantity", with: "10"
    fill_in "Price ($)", with: "10.00"
    click_on "Add Product"

    assert_button "Publish Event"
    accept_confirm do
      click_on "Publish Event"
    end

    assert_text "Event published!"

    # Verify new draft exists
    visit store_path
    assert_text "Weekly Sourdough"
    assert_text "Copy of Weekly Sourdough"
    assert_css ".badge.draft"

    # Verify dates of the new draft
    click_on "Copy of Weekly Sourdough"
    # The new draft should be Apr 1 + 1 week = Apr 8
    assert_text "Apr 8"
    assert_text "Repeats Weekly"
  end
end
