module Shop
  class OrdersController < ApplicationController
    before_action :require_authentication!
    before_action :set_store
    before_action :set_event

    # POST /shop/:slug/events/:event_id/order
    def create
      if @event.orders.exists?(user: current_user)
        return redirect_to shop_event_path(@store.slug, @event),
          alert: "You already have an order for this bake. Update or cancel it instead."
      end

      build_and_save_order(Order.new(user: current_user, event: @event), notice: "Order placed. We've sent a receipt to your email.", send_email: true)
    end

    # PATCH /shop/:slug/events/:event_id/order
    def update
      order = @event.orders.find_by!(user: current_user)
      build_and_save_order(order, notice: "Order updated.", send_email: false, replace_items: true)
    end

    # DELETE /shop/:slug/events/:event_id/order
    def destroy
      order = @event.orders.find_by!(user: current_user)

      unless @event.orders_open?
        return redirect_to shop_event_path(@store.slug, @event),
          alert: "Cannot cancel orders after the order window has closed."
      end

      order.cancel!
      redirect_to shop_event_path(@store.slug, @event), notice: "Order cancelled."
    end

    private

    def set_store
      @store = Store.find_by!(slug: params[:slug])
    end

    def set_event
      @event = @store.events.find(params[:event_id])
    end

    # Shared create + update flow.
    # - replace_items: when true (update), wipes existing items first.
    # - Inventory check runs inside a transaction with row locks on each
    #   touched product. The order's own existing items are excluded from
    #   the "sold" comparison so updating quantities doesn't self-block.
    def build_and_save_order(order, notice:, send_email:, replace_items: false)
      unless @event.orders_open?
        return redirect_to shop_event_path(@store.slug, @event),
          alert: "Sorry, orders for this bake have closed."
      end

      requested = parse_quantities(params[:items])

      if requested.empty?
        return redirect_to shop_event_path(@store.slug, @event),
          alert: "Please select at least one item."
      end

      if @event.delivery_enabled? && params.key?(:delivery_address)
        order.delivery_address = params[:delivery_address].presence
      end
      order.notes = params[:notes].presence

      oversold_product = nil
      saved = false

      ActiveRecord::Base.transaction do
        # Lock every product the customer is requesting plus any product
        # already on this order (so we can free its quantity for the recompute).
        product_ids = requested.keys
        product_ids |= order.order_items.pluck(:event_product_id) if replace_items
        products = @event.event_products.where(id: product_ids).lock("FOR UPDATE").index_by(&:id)

        # Wipe existing items so remaining stock is computed against the new
        # order shape, not the old one. dependent: :destroy not needed here
        # because we're inside a tx and won't commit if the rebuild fails.
        order.order_items.destroy_all if replace_items

        requested.each do |product_id, quantity|
          product = products[product_id]
          unless product
            order.errors.add(:base, "One of the requested products is no longer available.")
            raise ActiveRecord::Rollback
          end
          # remaining now reflects sold-not-counting-this-order since we wiped.
          if quantity > product.remaining
            oversold_product = product
            raise ActiveRecord::Rollback
          end

          order.order_items.build(
            event_product: product,
            quantity: quantity,
            unit_price_cents: product.price_cents
          )
        end

        if order.save
          saved = true
        else
          raise ActiveRecord::Rollback
        end
      end

      if oversold_product
        redirect_to shop_event_path(@store.slug, @event),
          alert: "Sorry, #{oversold_product.name} doesn't have that much left. Please adjust your order."
      elsif saved
        OrderMailer.with(order: order).confirmation_email.deliver_later if send_email
        redirect_to shop_event_path(@store.slug, @event), notice: notice
      else
        redirect_to shop_event_path(@store.slug, @event),
          alert: order.errors.full_messages.to_sentence.presence || "Could not save your order. Please try again."
      end
    end

    # `params[:items]` shape:
    #   { "<event_product_id>" => "<quantity>", ... }
    # Returns a hash of { product_id (Integer) => quantity (Integer) },
    # with zero/blank quantities dropped.
    def parse_quantities(raw)
      return {} unless raw.respond_to?(:to_unsafe_h) || raw.is_a?(Hash)
      hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw
      hash.each_with_object({}) do |(product_id, qty), out|
        q = qty.to_i
        out[product_id.to_i] = q if q > 0
      end
    end
  end
end
