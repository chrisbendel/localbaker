class GeocodeStoreJob < ApplicationJob
  queue_as :default

  def perform(store_id)
    store = Store.find(store_id)
    return if store.address.blank?

    if Rails.env.development?
      # Mock geocoding near user's house in Colchester, VT
      store.update(
        latitude: 44.501 + rand(-0.02..0.02),
        longitude: -73.199 + rand(-0.02..0.02)
      )
      Rails.logger.info("Mock geocoded store ##{store.id}: #{store.address}")
    else
      # Real geocoding in production using Nominatim
      result = Geocoder.search(store.address)

      if result.present?
        location = result.first
        store.update(
          latitude: location.latitude,
          longitude: location.longitude
        )
      else
        Rails.logger.warn("Failed to geocode store ##{store.id}: #{store.address}")
      end
    end
  rescue => e
    Rails.logger.error("Error geocoding store ##{store.id}: #{e.message}")
  end
end
