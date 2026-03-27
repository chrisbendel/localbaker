require "test_helper"

class EventTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "eventtester@example.com")
    @store = Store.create!(name: "My Store", slug: "my-store", user: @user)

    @event = @store.events.new(
      name: "Bread Drop",
      orders_close_at: 2.days.from_now,
      pickup_at: 3.days.from_now
    )
  end

  test "valid event" do
    assert_predicate @event, :valid?
  end

  test "requires a name" do
    @event.name = nil
    refute @event.valid?
    assert_includes @event.errors[:name], "can't be blank"
  end

  test "requires orders_close_at" do
    @event.orders_close_at = nil
    refute @event.valid?
    assert_includes @event.errors[:orders_close_at], "can't be blank"
  end

  test "requires pickup_at" do
    @event.pickup_at = nil
    refute @event.valid?
    assert_includes @event.errors[:pickup_at], "can't be blank"
  end

  test "belongs to store" do
    assert_equal @store, @event.store
  end

  test "orders_close_at must be before pickup_at" do
    @event.orders_close_at = @event.pickup_at + 1.hour
    refute @event.valid?
    assert_includes @event.errors[:orders_close_at], "must be before the pickup time"
  end

  test "cannot be deleted if there are orders" do
    @event.save!

    customer = User.create!(email: "customer-test@example.com")
    Order.create!(user: customer, event: @event)

    assert_not @event.destroy
    assert @event.errors.full_messages.join.downcase.include?("order")
  end

  test "can be deleted if no orders exist" do
    @event.save!
    assert @event.destroy
  end

  test "orders_open? is true when published and before orders_close_at" do
    @event.save!
    @event.event_products.create!(name: "Item", price: 10, quantity: 10)
    @event.publish!
    assert @event.orders_open?
  end

  test "orders_open? is false when orders_close_at has passed" do
    @event.orders_close_at = 1.hour.ago
    @event.pickup_at = 1.hour.from_now
    @event.save!(validate: false)
    @event.event_products.create!(name: "Item", price: 10, quantity: 10)
    @event.publish!
    refute @event.orders_open?
  end

  test "orders_open? is false for draft events" do
    @event.save!
    refute @event.orders_open?
  end

  test "orders_closed? is true when published and orders_close_at has passed" do
    @event.orders_close_at = 1.hour.ago
    @event.pickup_at = 1.hour.from_now
    @event.save!(validate: false)
    @event.event_products.create!(name: "Item", price: 10, quantity: 10)
    @event.publish!
    assert @event.orders_closed?
  end

  test "past? is true when pickup_at has passed" do
    @event.orders_close_at = 2.days.ago
    @event.pickup_at = 1.day.ago
    @event.save!(validate: false)
    assert @event.past?
  end

  test "past? is false when pickup_at is in the future" do
    refute @event.past?
  end

  test ":current scope excludes events with pickup_at older than 3 days" do
    @event.orders_close_at = 4.days.ago
    @event.pickup_at = 4.days.ago + 1.hour
    @event.save!(validate: false)
    @event.event_products.create!(name: "Item", price: 10, quantity: 10)
    @event.publish!
    refute_includes Event.current, @event
  end

  test ":current scope includes events with pickup_at within 3 days ago" do
    @event.orders_close_at = 2.days.ago
    @event.pickup_at = 2.days.ago + 1.hour
    @event.save!(validate: false)
    @event.event_products.create!(name: "Item", price: 10, quantity: 10)
    @event.publish!
    assert_includes Event.current, @event
  end

  # --- pickup_address / effective_pickup_address ---

  test "pickup_address is optional" do
    @event.pickup_address = nil
    assert_predicate @event, :valid?
  end

  test "effective_pickup_address returns the event's pickup_address when set" do
    @store.update!(address: "123 Home St, Portland, OR")
    @event.pickup_address = "The Climbing Gym, 456 Oak Ave, Portland, OR"
    assert_equal "The Climbing Gym, 456 Oak Ave, Portland, OR", @event.effective_pickup_address
  end

  test "effective_pickup_address falls back to store address when event has none" do
    @store.update!(address: "123 Home St, Portland, OR")
    @event.pickup_address = nil
    assert_equal "123 Home St, Portland, OR", @event.effective_pickup_address
  end

  test "effective_pickup_address returns nil when neither event nor store has an address" do
    @store.update!(address: nil)
    @event.pickup_address = nil
    assert_nil @event.effective_pickup_address
  end

  test "effective_pickup_address treats blank event pickup_address as absent" do
    @store.update!(address: "123 Home St, Portland, OR")
    @event.pickup_address = ""
    assert_equal "123 Home St, Portland, OR", @event.effective_pickup_address
  end
end
