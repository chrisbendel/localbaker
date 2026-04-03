require "test_helper"

class StorefrontControllerTest < ActionDispatch::IntegrationTest
  def setup
    @owner = User.create!(email: "owner-#{SecureRandom.hex(4)}@example.com")
    @store = Store.create!(name: "Test Store", slug: "test-store-#{SecureRandom.hex(4)}", user: @owner)
  end

  def publish_event(name:, orders_close_at:, pickup_at:)
    event = @store.events.create!(name: name, orders_close_at: orders_close_at, pickup_at: pickup_at)
    event.event_products.create!(name: "Item", price: 10, quantity: 10)
    event.publish!
    event
  end

  test "shows upcoming events on storefront" do
    publish_event(name: "Upcoming", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)

    get storefront_url(@store.slug)

    assert_response :success
    assert_select "a", text: /Upcoming/
  end

  test "shows events with pickup within the last 3 days" do
    recent = publish_event(name: "Recent", orders_close_at: 3.days.ago, pickup_at: 2.days.ago + 1.hour)
    recent.update_columns(orders_close_at: 3.days.ago, pickup_at: 2.days.ago + 1.hour)

    get storefront_url(@store.slug)

    assert_response :success
    assert_select "a", text: /Recent/
  end

  test "hides events with pickup older than 3 days" do
    old = publish_event(name: "Old Event", orders_close_at: 5.days.ago, pickup_at: 4.days.ago + 1.hour)
    old.update_columns(orders_close_at: 5.days.ago, pickup_at: 4.days.ago + 1.hour)

    get storefront_url(@store.slug)

    assert_response :success
    assert_select "a", text: /Old Event/, count: 0
  end

  test "hides draft events" do
    @store.events.create!(name: "Draft Event", orders_close_at: 1.day.from_now, pickup_at: 2.days.from_now)

    get storefront_url(@store.slug)

    assert_response :success
    assert_select "a", text: /Draft Event/, count: 0
  end

  test "includes open graph meta tags" do
    get storefront_url(@store.slug)

    assert_response :success
    assert_select "meta[property='og:title'][content='#{@store.name} | Local bakery near me']"
    assert_select "meta[property='og:description'][content*='#{@store.name}']"
    assert_select "meta[property='og:url'][content*='#{@store.slug}']"
    assert_select "meta[property='og:image']"
    assert_select "meta[property='og:site_name'][content='LocalBaker']"
  end
end
