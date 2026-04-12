require "test_helper"

class Stores::EventProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "producttester@example.com")
    @store = Store.create!(user: @user, name: "Test Store", slug: "test-store")
    @event = @store.events.create!(
      name: "Bread Pickup",
      orders_close_at: 1.day.from_now,
      pickup_starts_at: 2.days.from_now,
      pickup_ends_at: 2.days.from_now + 4.hours
    )
    @product = @event.event_products.create!(name: "Sourdough", price_cents: 1000, quantity: 10)
    sign_in_as(@user)
  end

  # --- ensure_event_not_past! guard ---

  test "GET new is blocked for past events" do
    @event.update_columns(pickup_starts_at: 2.days.ago, pickup_ends_at: 1.day.ago + 16.hours, orders_close_at: 2.days.ago)
    get new_event_event_product_path(@event)
    assert_redirected_to event_path(@event)
    follow_redirect!
    assert_select ".alert", /Past events cannot be edited/i
  end

  test "POST create is blocked for past events" do
    @event.update_columns(pickup_starts_at: 2.days.ago, pickup_ends_at: 1.day.ago + 16.hours, orders_close_at: 2.days.ago)
    assert_no_difference "EventProduct.count" do
      post event_event_products_path(@event), params: {
        event_product: {name: "New Product", price: 10, quantity: 5}
      }
    end
    assert_redirected_to event_path(@event)
  end

  test "GET edit is blocked for past events" do
    @event.update_columns(pickup_starts_at: 2.days.ago, pickup_ends_at: 1.day.ago + 16.hours, orders_close_at: 2.days.ago)
    get edit_event_product_path(@product)
    assert_redirected_to event_path(@event)
  end

  test "PATCH update is blocked for past events" do
    @event.update_columns(pickup_starts_at: 2.days.ago, pickup_ends_at: 1.day.ago + 16.hours, orders_close_at: 2.days.ago)
    patch event_product_path(@product), params: {event_product: {name: "Hacked"}}
    assert_redirected_to event_path(@event)
    @product.reload
    assert_equal "Sourdough", @product.name
  end

  test "DELETE destroy is blocked for past events" do
    @event.update_columns(pickup_starts_at: 2.days.ago, pickup_ends_at: 1.day.ago + 16.hours, orders_close_at: 2.days.ago)
    assert_no_difference "EventProduct.count" do
      delete event_product_path(@product)
    end
    assert_redirected_to event_path(@event)
  end
end
