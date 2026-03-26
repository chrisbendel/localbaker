module ApplicationHelper
  def nice_date(value)
    l(value, format: :nice_date) if value
  end

  def pickup_datetime(value)
    l(value, format: :pickup_datetime) if value
  end

  def render_breadcrumbs(links = [])
    render "application/breadcrumbs", links: links
  end

  def google_maps_url(address)
    "https://www.google.com/maps/dir/?api=1&destination=#{ERB::Util.url_encode(address)}"
  end
end
