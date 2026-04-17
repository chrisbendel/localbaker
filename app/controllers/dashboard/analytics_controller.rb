module Dashboard
  class AnalyticsController < BaseController
    before_action :require_pro!

    def show
      @start_date = parse_date(params[:start_date], 90.days.ago.to_date)
      @end_date = parse_date(params[:end_date], Date.today)

      @revenue_by_date = fetch_revenue_by_date(@start_date, @end_date)
      @orders_by_date = fetch_orders_by_date(@start_date, @end_date)
      @top_products_by_units = fetch_top_products_by_units(@start_date, @end_date)
      @top_products_by_revenue = fetch_top_products_by_revenue(@start_date, @end_date)
      @all_time_revenue = fetch_all_time_revenue
      @orders_by_event = fetch_orders_by_event(@start_date, @end_date)
      @subscribers_over_time = fetch_subscribers_over_time(@start_date, @end_date)
      @unique_customers_over_time = fetch_unique_customers_over_time(@start_date, @end_date)
    end

    private

    def parse_date(date_str, default)
      return default if date_str.blank?
      Date.parse(date_str)
    rescue ArgumentError
      default
    end

    def fetch_revenue_by_date(start_date, end_date)
      @store.orders
        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
        .joins(:order_items)
        .select("DATE(orders.created_at) as date, SUM(order_items.quantity * order_items.unit_price_cents / 100.0) as total")
        .group("DATE(orders.created_at)")
        .order("DATE(orders.created_at) ASC")
        .map { |row| [row.date, row.total.to_f.round(2)] }
        .to_h
    end

    def fetch_orders_by_date(start_date, end_date)
      @store.orders
        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
        .select("DATE(orders.created_at) as date, COUNT(*) as count")
        .group("DATE(orders.created_at)")
        .order("DATE(orders.created_at) ASC")
        .map { |row| [row.date.to_s, row.count] }
        .to_h
    end

    def fetch_top_products_by_units(start_date, end_date)
      EventProduct
        .joins(event: :orders, order_items: :order)
        .where(events: {store_id: @store.id}, orders: {created_at: start_date.beginning_of_day..end_date.end_of_day})
        .select("event_products.id, event_products.name, SUM(order_items.quantity) as units_sold, SUM(order_items.quantity * order_items.unit_price_cents / 100.0) as revenue_total")
        .group("event_products.id, event_products.name")
        .order("units_sold DESC")
        .limit(10)
    end

    def fetch_top_products_by_revenue(start_date, end_date)
      EventProduct
        .joins(event: :orders, order_items: :order)
        .where(events: {store_id: @store.id}, orders: {created_at: start_date.beginning_of_day..end_date.end_of_day})
        .select("event_products.id, event_products.name, SUM(order_items.quantity) as units_sold, SUM(order_items.quantity * order_items.unit_price_cents / 100.0) as revenue_total")
        .group("event_products.id, event_products.name")
        .order("revenue_total DESC")
        .limit(10)
    end

    def fetch_all_time_revenue
      @store.orders
        .joins(:order_items)
        .select("SUM(order_items.quantity * order_items.unit_price_cents / 100.0) as total")
        .pluck(:total)
        .first
        .to_f
        .round(2)
    end

    def fetch_orders_by_event(start_date, end_date)
      Event
        .where(store_id: @store.id)
        .joins(orders: :order_items)
        .where(orders: {created_at: start_date.beginning_of_day..end_date.end_of_day})
        .select("events.id, events.name, COUNT(DISTINCT orders.id) as order_count")
        .group("events.id, events.name")
        .order("order_count DESC")
    end

    def fetch_subscribers_over_time(start_date, end_date)
      @store.users
        .where(created_at: start_date.beginning_of_day..end_date.end_of_day, notifications_subscribed: true)
        .select("DATE(users.created_at) as date, COUNT(DISTINCT users.id) as count")
        .group("DATE(users.created_at)")
        .order("DATE(users.created_at) ASC")
        .map { |row| [row.date, row.count] }
        .to_h
    end

    def fetch_unique_customers_over_time(start_date, end_date)
      @store.orders
        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
        .select("DATE(orders.created_at) as date, COUNT(DISTINCT orders.user_id) as count")
        .group("DATE(orders.created_at)")
        .order("DATE(orders.created_at) ASC")
        .map { |row| [row.date, row.count] }
        .to_h
    end
  end
end
