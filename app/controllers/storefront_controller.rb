class StorefrontController < ApplicationController
  def show
    @store = Store.find_by!(slug: params[:slug])
    @events = @store.events.active_published.order(pickup_at: :asc)
    @notification = current_user&.store_notifications&.find_by(store: @store)

    #   TODO add QR code for downloading https://github.com/whomwah/rqrcode
  end
end
