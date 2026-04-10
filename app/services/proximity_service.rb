class ProximityService
  EventResult = Data.define(:event, :distance)

  def self.stores_near(latitude, longitude, radius_miles = 25)
    begin
      lat = Float(latitude)
      lon = Float(longitude)
    rescue ArgumentError
      # Invalid coordinates
      return Store.none
    end

    return Store.none unless (-90..90).cover?(lat) && (-180..180).cover?(lon)

    Store.geocoded.near([lat, lon], radius_miles)
  end

  def self.events_near(latitude, longitude, radius_miles = 25, limit: 50)
    stores_relation = stores_near(latitude, longitude, radius_miles)
    # Materialize stores to extract distance data (added by Geocoder.near)
    stores_with_distance = stores_relation.to_a

    stores_by_id = stores_with_distance.index_by(&:id)
    store_ids = stores_by_id.keys

    return [] if store_ids.empty?

    Event.ordering_open
      .where(store_id: store_ids)
      .includes(:store, :event_products)
      .order(:pickup_at)
      .limit(limit)
      .map do |event|
        EventResult.new(event: event, distance: stores_by_id[event.store_id]&.distance)
      end
      .sort_by { |r| [r.event.pickup_at, r.distance || 999] }
  end
end
