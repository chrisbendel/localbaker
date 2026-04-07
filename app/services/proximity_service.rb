class ProximityService
  def self.stores_near(latitude, longitude, radius_miles = 25)
    Store.geocoded.near([latitude.to_f, longitude.to_f], radius_miles)
  end

  def self.events_near(latitude, longitude, radius_miles = 25)
    # Get stores in range first
    stores = stores_near(latitude, longitude, radius_miles).to_a

    # Return events for those stores, calculating distance based on the store's position
    Event.active_published
      .where(store_id: stores.map(&:id))
      .includes(:store)
      .map do |event|
        # Attach distance to the event object for the view
        store_match = stores.find { |s| s.id == event.store_id }
        if store_match
          event.define_singleton_method(:distance) { store_match.distance }
        else
          event.define_singleton_method(:distance) { nil }
        end
        event
      end
      .sort_by { |event| [event.pickup_at, event.distance || 999] }
  end
end
