require "street_address"
module AddressParser
  module_function

  # Pure function: Takes a string, returns a normalized string or the original if unparseable
  def normalize(str)
    return str if str.blank?
    match = ::StreetAddress::US.parse(str)
    return str unless match

    street = [match.number, match.prefix, match.street, match.street_type, match.suffix].compact.join(" ")
    city = match.city.titleize
    state = match.state.upcase
    zip = match.postal_code

    normalized = if street.present?
      "#{street.strip.titleize}, #{city}, #{state}"
    else
      "#{city}, #{state}"
    end
    normalized += " #{zip}" if zip.present?

    normalized
  end

  # Pure function: Takes a string, returns "City, ST" or the original if unparseable
  def city_state(str)
    return nil if str.blank?
    match = ::StreetAddress::US.parse(str)
    return str unless match

    "#{match.city.titleize}, #{match.state.upcase}"
  end
end
