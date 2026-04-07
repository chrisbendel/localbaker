class ProximityService
  EventResult = Data.define(:event, :distance)

  def self.stores_near(latitude, longitude, radius_miles = 25)
    Store.geocoded.near([latitude.to_f, longitude.to_f], radius_miles)
  end

  def self.events_near(latitude, longitude, radius_miles = 25)
    stores = stores_near(latitude, longitude, radius_miles).to_a

    stores_by_id = stores.index_by(&:id)

    Event.active_published
      .where(store_id: stores_by_id.keys)
      .includes(:store, :event_products)
      .map do |event|
        EventResult.new(event: event, distance: stores_by_id[event.store_id]&.distance)
      end
      .sort_by { |r| [r.event.pickup_at, r.distance || 999] }
  end
end
