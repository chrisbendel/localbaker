require "application_system_test_case"

class BakeryDashboardTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email: "baker@example.com")
    @store = Store.create!(user: @user, name: "Morning Loaf", slug: "morning-loaf")
    sign_in_via_browser(@user)
  end

  test "viewing taking orders bakes" do
    event = @store.events.create!(
      name: "Saturday Sourdough",
      orders_close_at: 1.day.from_now,
      pickup_starts_at: 2.days.from_now,
      pickup_ends_at: 2.days.from_now + 4.hours
    )
    event.update_columns(published_at: Time.current)

    visit dashboard_path
    assert_text(/taking orders/i)
    assert_text "Saturday Sourdough"
    assert_text "0 orders"
  end

  test "viewing preparation bakes" do
    event = @store.events.create!(
      name: "Friday Focaccia",
      orders_close_at: 1.day.ago,
      pickup_starts_at: 1.day.from_now,
      pickup_ends_at: 1.day.from_now + 4.hours
    )
    event.update_columns(published_at: Time.current)

    visit dashboard_path
    assert_text(/preparation/i)
    assert_text "Friday Focaccia"
    assert_link "Prep list →"
  end

  test "viewing draft bakes" do
    @store.events.create!(
      name: "Sunday Sweets",
      published_at: nil,
      orders_close_at: 3.days.from_now,
      pickup_starts_at: 4.days.from_now,
      pickup_ends_at: 4.days.from_now + 4.hours
    )

    visit dashboard_path
    assert_text(/drafts/i)
    assert_text "Sunday Sweets"
    assert_text "Draft"
  end
  test "management actions are centralized on show page" do
    event = @store.events.create!(
      name: "Centralized Bake",
      orders_close_at: 1.day.from_now,
      pickup_starts_at: 2.days.from_now,
      pickup_ends_at: 2.days.from_now + 4.hours
    )

    visit dashboard_events_path
    within "tr", text: "Centralized Bake" do
      assert_no_link "Edit"
      assert_no_button "Reuse Event"
      assert_no_button "Delete Event"
      click_on "Centralized Bake"
    end

    assert_current_path event_path(event)
    assert_link "Edit Event"
    assert_button "Reuse Event"
    assert_button "Delete Event"
  end
end
