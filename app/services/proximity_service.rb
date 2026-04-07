class ProximityService
  EventResult = Data.define(:event, :distance)

  def self.stores_near(latitude, longitude, radius_miles = 25)
    Store.geocoded.near([latitude.to_f, longitude.to_f], radius_miles)
  end

  def self.events_near(latitude, longitude, radius_miles = 25)
    stores = stores_near(latitude, longitude, radius_miles).to_a

    Event.active_published
      .where(store_id: stores.map(&:id))
      .includes(:store)
      .map do |event|
        store_match = stores.find { |s| s.id == event.store_id }
        EventResult.new(event: event, distance: store_match&.distance)
      end
      .sort_by { |r| [r.event.pickup_at, r.distance || 999] }
  end
end
