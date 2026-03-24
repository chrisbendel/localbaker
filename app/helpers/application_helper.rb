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
end
