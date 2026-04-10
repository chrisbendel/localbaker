class StorefrontController < ApplicationController
  def show
    @store = Store.find_by!(slug: params[:slug])
    @events = @store.events.orders_open.order(pickup_at: :asc)
    @notification = current_user&.store_notifications&.find_by(store: @store)

    if current_user
      @personal_orders = current_user.orders
        .joins(:event)
        .where(events: {store_id: @store.id})
        .where("events.pickup_at >= ?", Time.current)
        .order("events.pickup_at ASC")
    end

    #   TODO add QR code for downloading https://github.com/whomwah/rqrcode
  end
end
