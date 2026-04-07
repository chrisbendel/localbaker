# Configure geocoding per environment
lookup = if Rails.env.test?
  # Use test lookup in test environment only — no external HTTP calls
  :test
else
  # Use Nominatim in production and development for real geocoding
  :nominatim
end

Geocoder.configure(
  lookup: lookup,
  ip_lookup: Rails.env.test? ? :test : :nominatim,
  http_headers: {
    user_agent: "LocalBaker (https://localbaker.app)"
  },
  cache: Rails.cache,
  cache_prefix: "geocoder:",
  cache_expiration: 7.days,
  use_https: true,
  timeout: 5,
  always_raise: []
)
