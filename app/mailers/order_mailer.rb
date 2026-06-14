class OrderMailer < ApplicationMailer
  def confirmation_email
    @order = params[:order]
    @event = @order.event
    @store = @event.store

    mail(
      to: @order.user.email,
      subject: "Order confirmed: #{@event.name} — #{@store.name}"
    )
  end

  def cancellation_email
    @order = params[:order]
    @event = @order.event
    @store = @event.store

    mail(
      to: @order.user.email,
      subject: "Order cancelled: #{@event.name} — #{@store.name}"
    )
  end

  # Sent when a baker cancels an entire event. The order is already destroyed by
  # the time this fires (emails fan out post-commit), so it takes primitives
  # snapshotted before the delete rather than an Order record.
  def event_cancellation
    @event_name = params[:event_name]
    @store_name = params[:store_name]
    @reason = params[:reason].presence

    mail(
      to: params[:to],
      subject: "Event cancelled: #{@event_name} — #{@store_name}"
    )
  end

  def pickup_reminder
    @order = params[:order]
    @event = @order.event
    @store = @event.store

    mail(
      to: @order.user.email,
      subject: "Pickup reminder: #{@event.name} tomorrow — #{@store.name}"
    )
  end
end
