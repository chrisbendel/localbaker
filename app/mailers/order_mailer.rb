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
