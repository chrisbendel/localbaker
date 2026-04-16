require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @owner = User.create!(email: "owner-#{SecureRandom.hex(4)}@example.com")
    @store = Store.create!(name: "Test Store", slug: "test-store-#{SecureRandom.hex(4)}", user: @owner, listed: true)

    # Create a published event with a future pickup date
    @event = @store.events.create!(
      name: "Test Event",
      orders_close_at: 1.day.from_now,
      pickup_starts_at: 2.days.from_now,
      pickup_ends_at: 2.days.from_now + 4.hours
    )
    @event.event_products.create!(name: "Item", price: 10, quantity: 10)
    @event.publish!
  end

  def test_sitemap_xml_response
    get sitemap_url(format: :xml)
    assert_response :success
    assert_match(/<?xml/, response.body)
    assert_match(/urlset/, response.body)
  end

  def test_sitemap_includes_listed_stores
    get sitemap_url(format: :xml)
    assert_response :success
    assert_match(/#{@store.slug}/, response.body)
  end

  def test_sitemap_includes_active_published_events
    get sitemap_url(format: :xml)
    assert_response :success
    assert_match(/events\/#{@event.id}/, response.body)
  end

  def test_sitemap_content_type
    get sitemap_url(format: :xml)
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
  end

  def test_sitemap_excludes_unlisted_stores
    unlisted_store = Store.create!(
      name: "Unlisted Store",
      slug: "unlisted-#{SecureRandom.hex(4)}",
      user: User.create!(email: "unlisted-#{SecureRandom.hex(4)}@example.com"),
      listed: false
    )

    get sitemap_url(format: :xml)
    assert_response :success
    assert_no_match(/#{unlisted_store.slug}/, response.body)
  end

  def test_sitemap_excludes_past_events
    past_event = @store.events.create!(
      name: "Past Event",
      orders_close_at: 5.days.ago,
      pickup_starts_at: 4.days.ago,
      pickup_ends_at: 4.days.ago + 4.hours
    )
    past_event.event_products.create!(name: "Item", price: 10, quantity: 10)
    past_event.publish!

    get sitemap_url(format: :xml)
    assert_response :success
    assert_no_match(/events\/#{past_event.id}/, response.body)
  end
end
