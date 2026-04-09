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
      pickup_at: 2.days.from_now
    )
    event.update_columns(published_at: Time.current)

    visit store_path
    assert_text "Taking Orders"
    assert_text "Saturday Sourdough"
    assert_text "0 orders"
  end

  test "viewing preparation bakes" do
    event = @store.events.create!(
      name: "Friday Focaccia",
      orders_close_at: 1.day.ago,
      pickup_at: 1.day.from_now
    )
    event.update_columns(published_at: Time.current)

    visit store_path
    assert_text "Preparation"
    assert_text "Friday Focaccia"
    assert_link "Prep list →"
  end

  test "viewing draft bakes" do
    @store.events.create!(
      name: "Sunday Sweets",
      published_at: nil,
      orders_close_at: 3.days.from_now,
      pickup_at: 4.days.from_now
    )

    visit store_path
    assert_text "Drafts"
    assert_text "Sunday Sweets"
    assert_text "Draft"
  end

  test "navigating to all events" do
    event = @store.events.create!(
      name: "Past Bake",
      orders_close_at: 11.days.ago,
      pickup_at: 9.days.ago
    )
    event.update_columns(published_at: 10.days.ago)

    visit store_path
    assert_no_text "Past Bake"

    click_on "View all events →"
    assert_current_path store_events_path
    assert_text "Events"
    assert_text "Past Bake"
  end

  test "management actions are centralized on show page" do
    event = @store.events.create!(
      name: "Centralized Bake",
      orders_close_at: 1.day.from_now,
      pickup_at: 2.days.from_now
    )

    visit store_events_path
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

  test "dashboard empty state" do
    visit store_path
    assert_text "Your bakery is quiet right now"
    assert_link "Schedule your next bake"
  end
end
