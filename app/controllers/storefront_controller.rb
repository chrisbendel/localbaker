class StorefrontController < ApplicationController
  def about
    @store = Store.find_by!(slug: params[:slug])
  end

  def show
    @store = Store.find_by!(slug: params[:slug])
    @events = @store.events.orders_open.order(pickup_at: :asc)

    if current_user
      @ordered_event_ids = current_user.orders
        .joins(:event)
        .where(events: {store_id: @store.id})
        .where("events.pickup_at >= ?", Time.current)
        .pluck("events.id")
        .to_set
    end

    #   TODO add QR code for downloading https://github.com/whomwah/rqrcode
  end
end
