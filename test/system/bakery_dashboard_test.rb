require "application_system_test_case"

class BakeryDashboardTest < ApplicationSystemTestCase
  setup do
    @baker = User.create!(email: "baker@example.com")
    @store = Store.create!(user: @baker, name: "The Crusty Loaf", slug: "crusty-loaf")
    sign_in_via_browser(@baker)
  end

  test "dashboard shows events in correct priority sections" do
    # 1. Taking Orders (Live)
    live_event = @store.events.create!(
      name: "Active Bake",
      orders_close_at: 1.day.from_now,
      pickup_at: 2.days.from_now
    )
    live_event.event_products.create!(name: "Bread", price_cents: 1000, quantity: 10)
    live_event.update!(published_at: Time.current)

    # 2. Preparation (Prep)
    prep_event = @store.events.create!(
      name: "Prep Bake",
      orders_close_at: 1.hour.ago,
      pickup_at: 1.day.from_now
    )
    prep_event.event_products.create!(name: "Cookies", price_cents: 500, quantity: 20)
    prep_event.update!(published_at: 1.day.ago)

    # 3. Draft
    draft_event = @store.events.create!(
      name: "Draft Bake",
      orders_close_at: 3.days.from_now,
      pickup_at: 4.days.from_now
    )
    assert draft_event.persisted?

    # 4. Past
    past_event = @store.events.create!(
      name: "Old Bake",
      orders_close_at: 10.days.ago,
      pickup_at: 9.days.ago
    )
    past_event.event_products.create!(name: "Old Bread", price_cents: 1000, quantity: 10)
    past_event.update!(published_at: 11.days.ago)

    visit store_path

    # Verify Taking Orders Section
    within "h4", text: "Taking Orders" do
      # Should see the live event
    end
    assert_link "Active Bake"

    # Verify Preparation Section
    within "h4", text: "Preparation" do
      # Should see the prep event
    end
    assert_link "Prep Bake"
    assert_link "Prep list →"

    # Verify Drafts Section
    within "h4", text: "Drafts" do
      # Should see the draft event
    end
    assert_link "Draft Bake"

    # Verify Past Events (inside details)
    assert_text "Past Events (1)"
    find("summary", text: "Past Events (1)").click
    assert_link "Old Bake"
    assert_button "Reuse"
  end

  test "dashboard empty state" do
    visit store_path
    assert_text "Your bakery is quiet right now"
    assert_link "Schedule your next bake"
  end
end
