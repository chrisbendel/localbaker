module ApplicationHelper
  def nice_date(value)
    l(value, format: :nice_date) if value
  end

  def pickup_datetime(value)
    l(value, format: :pickup_datetime) if value
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
    else relative_time_in_words(value)
    end
  end

  def render_breadcrumbs(links = [])
    render "application/breadcrumbs", links: links
  end

  def google_maps_url(address)
    "https://www.google.com/maps/dir/?api=1&destination=#{ERB::Util.url_encode(address)}"
  end

  def nav_link_to(label, path)
    active = current_page?(path)
    link_to label, path, class: (active ? "active" : nil)
  end
end
