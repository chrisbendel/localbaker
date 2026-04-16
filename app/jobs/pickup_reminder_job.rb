class PickupReminderJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    event = Event.find_by(id: event_id)
    return unless event&.published? && !event.past?
    return unless event.store.user.pro?

    event.orders.includes(:user, order_items: :event_product).each do |order|
      next if order.order_items.empty?
      OrderMailer.with(order: order).pickup_reminder.deliver_later
    end
  end
end
