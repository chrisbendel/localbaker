module ApplicationHelper
  def nice_date(value)
    l(value, format: :nice_date) if value
  end

  def pickup_datetime(value)
    l(value, format: :pickup_datetime) if value
  end

  def pickup_time(value)
    return unless value
    # Strip ":00" minutes for whole-hour times (e.g. "11am" instead of "11:00am")
    formatted = l(value, format: :pickup_time)
    formatted.sub(":00", "")
  end

  def pickup_window(event)
    return unless event.pickup_starts_at && event.pickup_ends_at
    date = pickup_datetime(event.pickup_starts_at)
    start_t = pickup_time(event.pickup_starts_at)
    end_t = pickup_time(event.pickup_ends_at)
    "#{date} · #{start_t}–#{end_t}"
  end

  # Relative date for customer-facing contexts where urgency matters.
  # "today" / "tomorrow" are surfaced explicitly; everything else uses
  # Rails' distance_of_time_in_words. Falls back to nice_date for past
  # dates and anything beyond ~3 weeks (where a real date is more useful).
  def fuzzy_date(value)
    return unless value

    case (value.to_date - Date.current).to_i
    when ..-1, 22.. then nice_date(value)
    when 0 then "today"
    when 1 then "tomorrow"
    else "in #{distance_of_time_in_words(Time.current, value)}"
    end
  end

  def render_breadcrumbs(links = [])
    render "application/breadcrumbs", links: links
  end

  def google_maps_url(address)
    "https://www.google.com/maps/dir/?api=1&destination=#{ERB::Util.url_encode(address)}"
  end

  def event_timing_summary(event)
    window = pickup_window(event)

    deadline_part = if event.orders_closed?
      "Orders closed"
    else
      "Orders close #{fuzzy_date(event.orders_close_at)}"
    end

    # TODO: Refactor phrasing if event is delivery_only (e.g., "Delivery Sunday" instead of "Pick up Sunday").
    "Pick up #{window} · #{deadline_part}"
  end

  def nav_link_to(label, path)
    active = current_page?(path)
    link_to label, path, class: (active ? "active" : nil)
  end
end
