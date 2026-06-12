module Dashboard
  class OrdersController < BaseController
    def update
      @order = Order.joins(:event).where(events: {store_id: @store.id}).find(params[:id])
      @order.update!(order_params)
      redirect_back fallback_location: orders_event_path(@order.event)
    end

    private

    def order_params
      params.expect(order: [:paid, :picked_up])
    end
  end
end
