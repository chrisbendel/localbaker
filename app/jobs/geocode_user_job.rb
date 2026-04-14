class GeocodeUserJob < ApplicationJob
  queue_as :default

  # A "good" Nominatim result has enough specificity to be useful for delivery
  # radius checks — at minimum a city/town and a postcode. A bare "10 Main Street"
  # with no city will resolve to something, but we can't trust it.
  #
  # This is area-level confidence only. When validating actual delivery addresses
  # (i.e. confirming a customer's door can be navigated to), upgrade the check to
  # also require `house_number` and `road` in the Nominatim result components.
  REQUIRED_ADDRESS_COMPONENTS = %w[postcode city town village].freeze

  def perform(user_id)
    user = User.find(user_id)

    if user.address.blank?
      user.update(latitude: nil, longitude: nil, geocode_failed: false)
      return
    end

    # Reset before each attempt so a corrected address gets a clean retry
    user.update(geocode_failed: false)

    # Pre-check: if AddressParser can't extract a city, the address is too
    # ambiguous to geocode reliably (e.g. "10 main street" with no city/state).
    # This runs in all environments so dev gets the same feedback as production.
    unless parseable_with_city?(user.address)
      user.update(latitude: nil, longitude: nil, geocode_failed: true)
      Rails.logger.warn("Address too ambiguous to geocode for user ##{user.id}: #{user.address}")
      return
    end

    if Rails.env.development?
      # Mock geocoding near Colchester, VT
      user.update(
        latitude: 44.501 + rand(-0.02..0.02),
        longitude: -73.199 + rand(-0.02..0.02)
      )
      Rails.logger.info("Mock geocoded user ##{user.id}: #{user.address}")
    else
      result = Geocoder.search(user.address).first

      if result && sufficient_specificity?(result)
        user.update(latitude: result.latitude, longitude: result.longitude)
      else
        user.update(latitude: nil, longitude: nil, geocode_failed: true)
        Rails.logger.warn("Failed to geocode user ##{user.id}: #{user.address}")
      end
    end
  rescue => e
    Rails.logger.error("Error geocoding user ##{user.id}: #{e.message}")
  end

  private

  def parseable_with_city?(address)
    match = StreetAddress::US.parse(address)
    match&.city.present?
  end

  def sufficient_specificity?(result)
    address_components = result.data.dig("address") || {}
    REQUIRED_ADDRESS_COMPONENTS.any? { |component| address_components[component].present? }
  end
end
