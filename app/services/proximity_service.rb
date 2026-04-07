class ProximityService
  # Earth's radius in miles
  EARTH_RADIUS_MILES = 3959

  def self.stores_near(latitude, longitude, radius_miles = 25)
    Store.geocoded.where(haversine_distance_sql(latitude, longitude) + " <= ?", radius_miles)
      .select("stores.*, (#{haversine_distance_sql(latitude, longitude)}) as distance")
      .order("distance ASC")
  end

  def self.events_near(latitude, longitude, radius_miles = 25)
    Event.active_published
      .joins(:store)
      .where(Store.arel_table[:id].in(stores_near(latitude, longitude, radius_miles).select(:id)))
      .select("events.*, stores.*, (#{haversine_distance_sql(latitude, longitude)}) as distance")
      .order("events.pickup_at ASC, distance ASC")
  end

  private

  def self.haversine_distance_sql(latitude, longitude)
    lat = latitude.to_f
    lng = longitude.to_f
    radius = EARTH_RADIUS_MILES

    # Haversine formula converted to SQL
    # Returns distance in miles between store coordinates and provided lat/lng
    <<-SQL
      #{radius} * 2 * ASIN(
        SQRT(
          POW(SIN(RADIANS((stores.latitude - #{lat}) / 2)), 2) +
          COS(RADIANS(#{lat})) * COS(RADIANS(stores.latitude)) *
          POW(SIN(RADIANS((stores.longitude - #{lng}) / 2)), 2)
        )
      )
    SQL
  end
end
