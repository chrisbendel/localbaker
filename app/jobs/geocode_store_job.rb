class GeocodeStoreJob < ApplicationJob
  queue_as :default

  def perform(store_id)
    store = Store.find(store_id)
    return if store.address.blank?

    if Rails.env.development?
      # Mock geocoding in development (use random coordinates near Vermont)
      store.update(
        latitude: 44.0 + rand(-0.5..0.5),
        longitude: -72.5 + rand(-0.5..0.5),
        geocoded_at: Time.current
      )
      Rails.logger.info("Mock geocoded store ##{store.id}: #{store.address}")
    else
      # Real geocoding in production using Nominatim
      result = Geocoder.search(store.address)

      if result.present?
        location = result.first
        store.update(
          latitude: location.latitude,
          longitude: location.longitude,
          geocoded_at: Time.current
        )
      else
        Rails.logger.warn("Failed to geocode store ##{store.id}: #{store.address}")
      end
    end
  rescue StandardError => e
    Rails.logger.error("Error geocoding store ##{store.id}: #{e.message}")
  end
end
