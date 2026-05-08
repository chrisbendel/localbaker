module Dashboard
  class OrdersController < BaseController
    def export
      orders = Order
        .joins(event: :store)
        .where(stores: {id: @store.id})
        .includes(:user, :event, order_items: :event_product)
        .order(created_at: :desc)

      filename = "orders-#{@store.slug}-#{Date.current}.csv"
      send_data Order.to_csv(orders), filename: filename, type: "text/csv"
    end
  end
end
