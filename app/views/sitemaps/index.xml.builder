xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # Shop pages
  @stores.each do |store|
    xml.url do
      xml.loc shop_url(store.slug)
      xml.lastmod store.updated_at.iso8601
      xml.changefreq "weekly"
      xml.priority "0.8"
    end
  end

  # Event pages
  @events.each do |event|
    xml.url do
      xml.loc shop_event_url(event.store.slug, event)
      xml.lastmod event.updated_at.iso8601
      xml.changefreq "weekly"
      xml.priority "0.7"
    end
  end
end
