class GeocodeUserJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    return if user.address.blank?

    if Rails.env.development?
      # Mock geocoding near user's house in Colchester, VT
      user.update(
        latitude: 44.501 + rand(-0.02..0.02),
        longitude: -73.199 + rand(-0.02..0.02)
      )
      Rails.logger.info("Mock geocoded user ##{user.id}: #{user.address}")
    else
      # Real geocoding in production using Nominatim
      result = Geocoder.search(user.address)

      if result.present?
        location = result.first
        user.update(
          latitude: location.latitude,
          longitude: location.longitude
        )
      else
        Rails.logger.warn("Failed to geocode user ##{user.id}: #{user.address}")
      end
    end
  rescue => e
    Rails.logger.error("Error geocoding user ##{user.id}: #{e.message}")
  end
end
