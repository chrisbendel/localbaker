module Shop
  class OrdersController < ApplicationController
    before_action :require_authentication!
    before_action :set_store
    before_action :set_event

    def confirm
      @order = @event.orders.find_by!(user: current_user)

      # Assign delivery address (blank clears it, ignored entirely for pickup-only events)
      if @event.delivery_enabled? && params.key?(:delivery_address)
        @order.delivery_address = params[:delivery_address].presence
      end

      if params.key?(:notes)
        @order.notes = params[:notes].presence
      end

      oversold_product = nil
      confirmed = false

      ActiveRecord::Base.transaction do
        # Lock each product row, then re-check remaining stock against this
        # user's requested quantity. Since sold() counts confirmed-only and
        # this order is still unconfirmed, our own items don't count toward
        # remaining — so the comparison is item.quantity vs true availability.
        @order.order_items.includes(:event_product).each do |item|
          product = item.event_product
          product.lock!
          if item.quantity > product.remaining
            oversold_product = product
            raise ActiveRecord::Rollback
          end
        end

        if @order.save
          @order.confirm!
          confirmed = true
        end
      end

      if oversold_product
        redirect_to shop_event_path(@store.slug, @event),
          alert: "Sorry, #{oversold_product.name} sold out before you could check out. Please update your order."
      elsif confirmed
        OrderMailer.with(order: @order).confirmation_email.deliver_later
        redirect_to shop_event_path(@store.slug, @event), notice: "Order confirmed! We've sent a receipt to your email."
      else
        error_message = @order.errors.full_messages.to_sentence.presence || "Could not confirm order. Please try again."
        redirect_to shop_event_path(@store.slug, @event), alert: error_message
      end
    end

    def unconfirm
      @order = @event.orders.find_by!(user: current_user)
      @order.unconfirm!
      redirect_to shop_event_path(@store.slug, @event)
    end

    def update
      @order = @event.orders.find_by!(user: current_user)
      @order.update!(notes: params[:notes].presence)
      redirect_to shop_event_path(@store.slug, @event), notice: "Note saved."
    end

    def destroy
      @order = @event.orders.find_by!(user: current_user)

      unless @order.confirmed?
        redirect_to shop_event_path(@store.slug, @event), alert: "Can only cancel confirmed orders."
        return
      end

      unless @event.orders_open?
        redirect_to shop_event_path(@store.slug, @event), alert: "Cannot cancel orders after the order window has closed."
        return
      end

      @order.cancel!
      redirect_to shop_event_path(@store.slug, @event), notice: "Order cancelled."
    end

    private

    def set_store
      @store = Store.find_by!(slug: params[:slug])
    end

    def set_event
      @event = @store.events.find(params[:id])
    end
  end
end
