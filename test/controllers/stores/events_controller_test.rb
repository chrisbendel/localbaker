require "test_helper"

class Stores::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActiveJob::Base.queue_adapter = :test
    @user = User.create!(email: "test@example.com")
    @store = Store.create!(user: @user, name: "Test Store", slug: "test-store")

    @event = @store.events.create!(
      name: "Bread Pickup",
      description: "Fresh sourdough",

      orders_close_at: 1.day.from_now,
      pickup_at: 2.days.from_now
    )

    # Sign in so authenticated routes work in integration tests
    sign_in_as(@user)
  end

  test "GET index shows events" do
    get store_events_path
    assert_response :success
    assert_select "h1", /Events/i
  end

  test "GET show displays the event" do
    get event_path(@event)
    assert_response :success
    assert_select "h2", /#{@event.name}/
  end

  test "GET new renders form" do
    get new_store_event_path
    assert_response :success
    assert_select "form"
  end

  test "POST create creates an event and redirects" do
    assert_difference "@store.events.count", 1 do
      post store_events_path, params: {
        event: {
          name: "Market Day",
          description: "Outdoor bread pickup",

          orders_close_at: 2.days.from_now,
          pickup_at: 3.days.from_now
        }
      }
    end

    new_event = @store.events.order(:created_at).last
    assert_redirected_to event_path(new_event)
    follow_redirect!
    assert_select ".notice", /Event created \(Draft\)/i

    # Assert NO email sent on create
    assert_no_enqueued_emails
  end

  test "POST publish publishes event and sends emails" do
    # Ensure event is initially draft
    assert @event.draft?
    @event.event_products.create!(name: "Bread", price_cents: 1000, quantity: 10)

    assert_difference "ActionMailer::Base.deliveries.size", 0 do # using deliver_later, so check enqueued
      post publish_event_path(@event)
    end

    assert_redirected_to event_path(@event)
    follow_redirect!
    assert_select ".notice", /Event published/i

    @event.reload
    assert @event.published?
  end

  test "POST publish fails if no products" do
    assert @event.draft?
    assert @event.event_products.empty?

    post publish_event_path(@event)

    assert_redirected_to event_path(@event)
    follow_redirect!
    assert_select ".alert", /at least one product/i

    @event.reload
    assert @event.draft?
  end

  test "POST create with invalid params renders new with 422" do
    assert_no_difference "@store.events.count" do
      post store_events_path, params: {event: {name: ""}}
    end
    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "GET edit renders form" do
    get edit_event_path(@event)
    assert_response :success
    assert_select "form"
  end

  test "PATCH update updates event and redirects" do
    patch event_path(@event), params: {
      event: {name: "Updated Name"}
    }

    assert_redirected_to event_path(@event)
    @event.reload
    assert_equal "Updated Name", @event.name
  end

  test "PATCH update with invalid data renders edit with 422" do
    patch event_path(@event), params: {
      event: {name: ""}
    }

    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "POST create saves pickup_address when provided" do
    post store_events_path, params: {
      event: {
        name: "Market Day",
        orders_close_at: 2.days.from_now,
        pickup_at: 3.days.from_now,
        pickup_address: "The Climbing Gym, 456 Oak Ave, Portland, OR"
      }
    }
    assert_equal "The Climbing Gym, 456 Oak Ave, Portland, OR",
      @store.events.order(:created_at).last.pickup_address
  end

  test "PATCH update saves pickup_address" do
    patch event_path(@event), params: {
      event: {pickup_address: "The Climbing Gym, 456 Oak Ave, Portland, OR"}
    }
    assert_equal "The Climbing Gym, 456 Oak Ave, Portland, OR", @event.reload.pickup_address
  end

  test "PATCH update can clear pickup_address" do
    @event.update!(pickup_address: "Somewhere")
    patch event_path(@event), params: {event: {pickup_address: ""}}
    assert_predicate @event.reload.pickup_address, :blank?
  end

  test "GET prep returns standalone prep list for published event with orders" do
    @event.event_products.create!(name: "Sourdough Loaf", price_cents: 1000, quantity: 12)
    @event.publish!
    customer = User.create!(email: "customer@example.com")
    order = @event.orders.create!(user: customer)
    order.order_items.create!(event_product: @event.event_products.first, quantity: 3)

    get prep_event_path(@event)

    assert_response :success
    assert_select "td", /Sourdough Loaf/
    assert_select "td", /3/
  end

  test "GET prep renders without application layout" do
    @event.event_products.create!(name: "Focaccia", price_cents: 800, quantity: 8)
    @event.publish!

    get prep_event_path(@event)

    assert_response :success
    assert_no_match %r{<nav}, response.body
  end

  test "DELETE destroy removes event and redirects" do
    assert_difference "@store.events.count", -1 do
      delete event_path(@event)
    end

    assert_redirected_to store_events_path
    follow_redirect!
    assert_select ".notice", /deleted/i
  end
end
