module Storefront
  class OrdersController < ApplicationController
    before_action :require_authentication!
    before_action :set_store
    before_action :set_event

    def confirm
      @order = @event.orders.find_by!(user: current_user)

      # Save delivery address if provided
      if params[:delivery_address].present?
        @order.delivery_address = params[:delivery_address]
      end

      if @order.save && @order.confirm!
        OrderMailer.with(order: @order).confirmation_email.deliver_later
        redirect_to storefront_event_path(@store.slug, @event), notice: "Order confirmed! We've sent a receipt to your email."
      else
        redirect_to storefront_event_path(@store.slug, @event), alert: "Could not confirm order. Please try again."
      end
    end

    def unconfirm
      @order = @event.orders.find_by!(user: current_user)
      @order.unconfirm!
      redirect_to storefront_event_path(@store.slug, @event)
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
