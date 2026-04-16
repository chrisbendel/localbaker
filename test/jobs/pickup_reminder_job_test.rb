require "test_helper"

class PickupReminderJobTest < ActiveJob::TestCase
  setup do
    @baker = User.create!(email: "baker@example.com", plan: "pro")
    @store = Store.create!(name: "Test Bakery", slug: "test-bakery", user: @baker, address: "123 Main St")
    @event = @store.events.create!(
      name: "Big Bake",
      orders_close_at: 1.hour.from_now,
      pickup_starts_at: 2.days.from_now,
      pickup_ends_at: 2.days.from_now + 4.hours
    )
    @product = @event.event_products.create!(name: "Sourdough", quantity: 10, price_cents: 1200)
    @event.update_columns(published_at: Time.current)
    @customer = User.create!(email: "customer@example.com")
    @order = @event.orders.create!(user: @customer, confirmed_at: Time.current)
    @order.order_items.create!(event_product: @product, quantity: 1)
    ActionMailer::Base.deliveries.clear
  end

  test "sends pickup_reminder to each customer with items" do
    perform_enqueued_jobs do
      PickupReminderJob.new.perform(@event.id)
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [@customer.email], ActionMailer::Base.deliveries.first.to
    assert_match "Pickup reminder", ActionMailer::Base.deliveries.first.subject
  end

  test "skips orders with no items" do
    empty_customer = User.create!(email: "empty@example.com")
    @event.orders.create!(user: empty_customer)

    perform_enqueued_jobs do
      PickupReminderJob.new.perform(@event.id)
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "does nothing for unknown event id" do
    perform_enqueued_jobs do
      PickupReminderJob.new.perform(0)
    end
    assert_empty ActionMailer::Base.deliveries
  end

  test "does nothing for unpublished event" do
    @event.update_columns(published_at: nil)

    perform_enqueued_jobs do
      PickupReminderJob.new.perform(@event.id)
    end
    assert_empty ActionMailer::Base.deliveries
  end

  test "job is scheduled 24h before pickup when event is published" do
    event = @store.events.build(
      name: "Future Bake",
      orders_close_at: 2.days.from_now,
      pickup_starts_at: 4.days.from_now,
      pickup_ends_at: 4.days.from_now + 4.hours
    )
    event.event_products.build(name: "Croissant", quantity: 5, price_cents: 500)

    assert_enqueued_with(job: PickupReminderJob, at: 4.days.from_now - 24.hours) do
      event.publish!
    end
  end

  test "reschedules job when pickup_starts_at changes" do
    new_pickup = 5.days.from_now
    assert_enqueued_with(job: PickupReminderJob, at: new_pickup - 24.hours) do
      @event.update!(
        pickup_starts_at: new_pickup,
        pickup_ends_at: new_pickup + 4.hours,
        orders_close_at: 1.day.from_now
      )
    end
  end
end
