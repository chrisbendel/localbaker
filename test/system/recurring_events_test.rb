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

    orders_close_date = 1.day.from_now.to_date
    pickup_date = 2.days.from_now.to_date
    next_pickup_date = pickup_date + 1.week

    # Use execute_script to set the value directly
    execute_script("document.getElementById('event_orders_close_at').value = '#{orders_close_date}'")
    execute_script("document.getElementById('event_pickup_at').value = '#{pickup_date}'")

    select "Weekly", from: "Repeat cadence"
    click_on "Create Event"

    click_on "Add a product"
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
    assert_text(/drafts/i)

    # Verify dates of the new draft
    click_on "Copy of Weekly Sourdough"
    # The new draft should be Apr 1 + 1 week = Apr 8
    assert_text next_pickup_date.strftime("%b %-d")
    assert_text "Repeats Weekly"
  end
end
