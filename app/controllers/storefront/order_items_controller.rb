module Storefront
  class OrderItemsController < ApplicationController
    before_action :require_authentication!
    before_action :set_store, only: [:create]
    before_action :set_event, only: [:create]
    before_action :set_product, only: [:create]

    def create
      unless @event.orders_open?
        redirect_to storefront_event_path(@store.slug, @event), alert: "Sorry, orders for this event are closed."
        return
      end

      order = Order.find_or_create_by!(user: current_user, event: @event)

      @product.with_lock do
        if @product.remaining < 1
          redirect_to storefront_event_path(@store.slug, @event), alert: "Sorry, that item is out of stock!"
          return
        end

        item = order.order_items.find_or_initialize_by(event_product: @product)

        if item.new_record?
          item.quantity = 1
          item.unit_price_cents = @product.price_cents
        else
          item.quantity += 1
        end

        item.save!
      end

      redirect_to storefront_event_path(@store.slug, @event), notice: "Added #{@product.name}"
    end

    def destroy
      item = current_user.order_items.find(params[:id])
      @event = item.order.event
      @store = @event.store
      product_name = item.event_product.name

      unless @event.orders_open?
        redirect_to storefront_event_path(@store.slug, @event), alert: "Sorry, orders for this event are closed."
        return
      end

      item.destroy!

      redirect_to storefront_event_path(@store.slug, @event), notice: "Removed #{product_name}"
    end

    private

    def set_store
      @store = Store.find_by!(slug: params[:slug])
    end

    def set_event
      @event = @store.events.find(params[:event_id])
    end

    def set_product
      @product = @event.event_products.find(params[:event_product_id])
    end
  end
end
