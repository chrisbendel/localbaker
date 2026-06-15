module Shop
  class EventsController < ApplicationController
    before_action :set_store
    before_action :set_event

    def show
      @products = @event.event_products
      @order = @event.orders.find_by(user: current_user)
    end

    private

    def set_store
      @store = Store.find_by!(slug: params[:slug])
    end

    def set_event
      @event = @store.events.published.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to shop_path(@store.slug),
        alert: "Can't find this event — it may have been cancelled or removed."
    end
  end
end
