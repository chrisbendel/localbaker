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
end
