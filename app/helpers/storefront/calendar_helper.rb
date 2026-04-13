module Storefront
  module CalendarHelper
    def google_calendar_url(event)
      summary = "Order Pickup: #{event.name} — #{event.store.name}"
      start_time = event.pickup_starts_at.strftime("%Y%m%dT%H%M%S")
      end_time = event.pickup_ends_at.strftime("%Y%m%dT%H%M%S")
      location = event.address
      description = "Pick up your LocalBaker order from #{event.store.name}."

      params = {
        action: "TEMPLATE",
        text: summary,
        dates: "#{start_time}/#{end_time}",
        details: description,
        location: location
      }

      "https://www.google.com/calendar/render?#{params.to_query}"
    end

    def ics_export(event)
      summary = "Order Pickup: #{event.name} — #{event.store.name}"
      start_time = event.pickup_starts_at.strftime("%Y%m%dT%H%M%S")
      end_time = event.pickup_ends_at.strftime("%Y%m%dT%H%M%S")
      location = event.address
      description = "Pick up your LocalBaker order from #{event.store.name}."
      timestamp = Time.current.strftime("%Y%m%dT%H%M%S")
      uid = "event-#{event.id}-#{event.updated_at.to_i}@localbaker.com"

      <<~ICS
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//LocalBaker//EN
        CALSCALE:GREGORIAN
        METHOD:PUBLISH
        BEGIN:VEVENT
        UID:#{uid}
        DTSTAMP:#{timestamp}
        DTSTART:#{start_time}
        DTEND:#{end_time}
        SUMMARY:#{summary}
        LOCATION:#{location}
        DESCRIPTION:#{description}
        END:VEVENT
        END:VCALENDAR
      ICS
    end
  end
end
