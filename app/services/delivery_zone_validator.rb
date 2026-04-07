class DeliveryZoneValidator
  def self.valid_for_delivery?(store, address)
    return true if store.delivery_zone_type.blank?

    case store.delivery_zone_type
    when "radius"
      validate_radius_zone(store, address)
    when "postal_codes"
      validate_postal_codes_zone(store, address)
    else
      true
    end
  end

  private

  def self.validate_radius_zone(store, address)
    return false unless store.latitude.present? && store.longitude.present?
    return false unless store.delivery_zone_radius_miles.present?

    # Geocode the delivery address
    result = Geocoder.search(address)
    return false if result.blank?

    location = result.first
    distance = ProximityService::EARTH_RADIUS_MILES * Math.acos(
      Math.sin(Math.radians(store.latitude)) * Math.sin(Math.radians(location.latitude)) +
      Math.cos(Math.radians(store.latitude)) * Math.cos(Math.radians(location.latitude)) *
      Math.cos(Math.radians(location.longitude - store.longitude))
    )

    distance <= store.delivery_zone_radius_miles
  rescue StandardError => e
    Rails.logger.error("Error validating delivery zone: #{e.message}")
    false
  end

  def self.validate_postal_codes_zone(store, address)
    return false unless store.delivery_zone_postal_codes.present?

    allowed_zips = store.delivery_zone_postal_codes.split(",").map(&:strip).map(&:upcase)

    # Extract ZIP code from address (simple regex - assumes US format)
    # Matches 5-digit or 9-digit ZIP codes
    zip_match = address.match(/\b(\d{5}(?:-\d{4})?)\b/)
    return false unless zip_match

    zip = zip_match[1]
    allowed_zips.include?(zip)
  end

  def self.radians(degrees)
    degrees * Math::PI / 180
  end
end
