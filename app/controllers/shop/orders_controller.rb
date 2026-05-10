module Shop
  class OrdersController < ApplicationController
    # Single-form ordering: customer submits a quantity per product. Order is
    # created (or replaced wholesale) atomically. No cart state.
    #
    # Errors live on the Order itself; controller actions read order.errors
    # and flash them. No row locks — low traffic + honor system means we accept
    # rare oversell races. Add locks if it ever matters.

    before_action :require_authentication!
    before_action :set_store
    before_action :set_event

    # POST /shop/:slug/events/:event_id/order
    def create
      if @event.orders.exists?(user: current_user)
        return redirect_to event_path,
          alert: "You already have an order for this bake. Update or cancel it instead."
      end

      order = Order.new(user: current_user, event: @event)
      if save_order(order)
        OrderMailer.with(order: order).confirmation_email.deliver_later
        redirect_to event_path, notice: "Order placed. We've sent a receipt to your email."
      else
        redirect_to event_path, alert: order.errors.full_messages.to_sentence
      end
    end

    # PATCH /shop/:slug/events/:event_id/order
    def update
      order = @event.orders.find_by!(user: current_user)
      if save_order(order)
        redirect_to event_path, notice: "Order updated."
      else
        redirect_to event_path, alert: order.errors.full_messages.to_sentence
      end
    end

    # DELETE /shop/:slug/events/:event_id/order
    def destroy
      order = @event.orders.find_by!(user: current_user)
      unless @event.orders_open?
        return redirect_to event_path, alert: "Cannot cancel orders after the order window has closed."
      end

      order.cancel!
      redirect_to event_path, notice: "Order cancelled."
    end

    private

    def set_store
      @store = Store.find_by!(slug: params[:slug])
    end

    def set_event
      @event = @store.events.find(params[:event_id])
    end

    def event_path
      shop_event_path(@store.slug, @event)
    end

    # Wipe + rebuild items from request params, then save. Errors accumulate
    # on the order; caller flashes order.errors.full_messages.
    def save_order(order)
      unless @event.orders_open?
        order.errors.add(:base, "Sorry, orders for this bake have closed.")
        return false
      end

      # params[:items] shape: { "<event_product_id>" => "<quantity>" }
      requested = (params[:items]&.to_unsafe_h || {})
        .transform_keys(&:to_i)
        .transform_values(&:to_i)
        .select { |_, qty| qty > 0 }

      if requested.empty?
        order.errors.add(:base, "Please select at least one item.")
        return false
      end

      order.delivery_address = params[:delivery_address].presence if @event.delivery_enabled?
      order.notes = params[:notes].presence

      ActiveRecord::Base.transaction do
        order.order_items.destroy_all

        requested.each do |product_id, quantity|
          product = @event.event_products.find_by(id: product_id)
          next unless product

          if quantity > product.remaining
            order.errors.add(:base, "Sorry, #{product.name} doesn't have that much left. Please adjust your order.")
            raise ActiveRecord::Rollback
          end

          order.order_items.build(
            event_product: product,
            quantity: quantity,
            unit_price_cents: product.price_cents
          )
        end

        raise ActiveRecord::Rollback if order.errors.any?
        order.save!
      end

      order.errors.empty? && order.persisted?
    end
  end
end
