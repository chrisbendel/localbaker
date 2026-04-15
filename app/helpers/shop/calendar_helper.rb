module Shop
  module CalendarHelper
    def google_calendar_url(event)
      params = {
        action: "TEMPLATE",
        text: "Pick up #{event.name} from #{event.store.name}",
        dates: [event.pickup_starts_at, event.pickup_ends_at].map { |t| t.strftime("%Y%m%dT%H%M%S") }.join("/"),
        location: event.address,
        details: "Order details: #{orders_url}"
      }
      "https://www.google.com/calendar/render?#{params.to_query}"
    end
  end
end
