class GeocodeStoreJob < ApplicationJob
  queue_as :default

  # A "good" Nominatim result has enough specificity to be useful for proximity
  # matching — at minimum a city/town and a postcode. A bare street name with no
  # city/zip is too ambiguous to trust.
  # Note: delivery-level validation (requiring house_number + road) is a separate
  # concern — this check covers area-level confidence only.
  REQUIRED_ADDRESS_COMPONENTS = %w[postcode city town village].freeze

  def perform(store_id)
    store = Store.find(store_id)

    if store.address.blank?
      store.update(latitude: nil, longitude: nil, geocode_failed: false)
      return
    end

    # Reset before each attempt so a corrected address gets a clean retry
    store.update(geocode_failed: false)

    # Pre-check: if AddressParser can't extract a city, the address is too
    # ambiguous to geocode reliably (e.g. "10 main street" with no city/state).
    # Runs in all environments so dev gets the same feedback as production.
    unless parseable_with_city?(store.address)
      store.update(latitude: nil, longitude: nil, geocode_failed: true)
      Rails.logger.warn("Address too ambiguous to geocode for store ##{store.id}: #{store.address}")
      return
    end

    if Rails.env.development?
      # Mock geocoding near Colchester, VT
      store.update(
        latitude: 44.501 + rand(-0.02..0.02),
        longitude: -73.199 + rand(-0.02..0.02)
      )
      Rails.logger.info("Mock geocoded store ##{store.id}: #{store.address}")
    else
      result = Geocoder.search(store.address).first

      if result && sufficient_specificity?(result)
        store.update(latitude: result.latitude, longitude: result.longitude)
      else
        store.update(latitude: nil, longitude: nil, geocode_failed: true)
        Rails.logger.warn("Failed to geocode store ##{store.id}: #{store.address}")
      end
    end
  rescue => e
    Rails.logger.error("Error geocoding store ##{store.id}: #{e.message}")
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
