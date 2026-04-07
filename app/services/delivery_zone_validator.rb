module DeliveryZoneValidator
  module_function

  def valid_for_delivery?(store, address)
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

  def validate_radius_zone(store, address)
    return false unless store.latitude.present? && store.longitude.present?
    return false unless store.delivery_zone_radius_miles.present?

    # Geocode the delivery address
    result = Geocoder.search(address)
    return false if result.blank?

    location = result.first

    # Use Geocoder native calculations for the distance
    distance = Geocoder::Calculations.distance_between(
      [store.latitude, store.longitude],
      [location.latitude, location.longitude]
    )

    distance <= store.delivery_zone_radius_miles
  rescue => e
    Rails.logger.error("Error validating delivery zone: #{e.message}")
    false
  end

  def validate_postal_codes_zone(store, address)
    return false unless store.delivery_zone_postal_codes.present?

    allowed_zips = store.delivery_zone_postal_codes.split(/[\n,]/).map(&:strip).map(&:upcase).reject(&:empty?)

    # Extract ZIP code from address (simple regex - assumes US format)
    # Matches 5-digit or 9-digit ZIP codes
    zip_match = address.match(/\b(\d{5}(?:-\d{4})?)\b/)
    return false unless zip_match

    zip = zip_match[1]
    allowed_zips.include?(zip)
  end
end
