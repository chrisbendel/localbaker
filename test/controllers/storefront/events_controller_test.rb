require "test_helper"

module Storefront
  class EventsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @owner = User.create!(email: "owner-#{SecureRandom.hex(4)}@example.com")
      @store = Store.create!(name: "Test Store", slug: "test-store-#{SecureRandom.hex(4)}", user: @owner)
      @event = @store.events.create!(name: "Test Event", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)
      @event_product = @event.event_products.create!(name: "Sourdough", price: 10, quantity: 100)
      @event.publish!
    end

    test "should get show for published event" do
      get storefront_event_url(@store.slug, @event)
      assert_response :success
    end

    test "should give 404 for unknown store" do
      get storefront_event_url("unknown-store", @event)
      assert_response :not_found
    end

    test "should give 404 for unknown event" do
      get storefront_event_url(@store.slug, "999999")
      assert_response :not_found
    end

    test "should give 404 for draft event" do
      draft_event = @store.events.create!(name: "Draft Event", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)
      # Create product so it can be published (though we don't publish it, validation might require it if we tried to publish, but here we just need it created)
      draft_event.event_products.create!(name: "Item", price: 10, quantity: 10)

      get storefront_event_url(@store.slug, draft_event)
      assert_response :not_found
    end

    test "should still be viewable after orders close" do
      # Close the order window without going through validations
      @event.update_columns(orders_close_at: 1.hour.ago)

      get storefront_event_url(@store.slug, @event)
      assert_response :success
    end

    test "includes open graph meta tags" do
      get storefront_event_url(@store.slug, @event)

      assert_response :success
      assert_select "meta[property='og:title'][content*='#{@event.name}']"
      assert_select "meta[property='og:title'][content*='#{@store.name}']"
      assert_select "meta[property='og:description']"
      assert_select "meta[property='og:url'][content*='#{@store.slug}']"
      assert_select "meta[property='og:image']"
      assert_select "meta[property='og:site_name'][content='LocalBaker']"
    end

    test "uses event description in og:description when present" do
      @event.update!(description: "A special weekend bake.")

      get storefront_event_url(@store.slug, @event)

      assert_select "meta[property='og:description'][content='A special weekend bake.']"
    end

    test "uses fallback text in og:description when no event description" do
      @event.update_columns(description: nil)

      get storefront_event_url(@store.slug, @event)

      assert_select "meta[property='og:description'][content*='#{@store.name}']"
    end

    # --- pickup location display ---

    test "shows event pickup_address as a maps link" do
      @event.update!(pickup_address: "The Climbing Gym, 456 Oak Ave, Portland, OR")

      get storefront_event_url(@store.slug, @event)

      assert_response :success
      assert_select "a[href*='google.com/maps']", text: "The Climbing Gym, 456 Oak Ave, Portland, OR"
    end

    test "falls back to store address when event has no pickup_address" do
      @store.update!(address: "123 Home St, Portland, OR")
      @event.update_columns(pickup_address: nil)

      get storefront_event_url(@store.slug, @event)

      assert_response :success
      assert_select "a[href*='google.com/maps']", text: "123 Home St, Portland, OR"
    end

    test "event pickup_address takes precedence over store address" do
      @store.update!(address: "123 Home St, Portland, OR")
      @event.update!(pickup_address: "The Climbing Gym, 456 Oak Ave, Portland, OR")

      get storefront_event_url(@store.slug, @event)

      assert_response :success
      assert_select "a[href*='google.com/maps']", text: "The Climbing Gym, 456 Oak Ave, Portland, OR"
      assert_no_match(/123 Home St/, response.body)
    end

    test "shows no maps link when neither event nor store has an address" do
      @store.update!(address: nil)
      @event.update_columns(pickup_address: nil)

      get storefront_event_url(@store.slug, @event)

      assert_response :success
      assert_select "a[href*='google.com/maps']", count: 0
    end
  end
end
