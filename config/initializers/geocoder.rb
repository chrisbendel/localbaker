Geocoder.configure(
  # Use Nominatim in production for real geocoding
  lookup: :nominatim,

  # Nominatim requires a user-agent header
  http_headers: {
    user_agent: "LocalBaker (https://localbaker.app)"
  },

  # Cache results to avoid duplicate API calls
  cache: Rails.cache,
  cache_prefix: "geocoder:",

  # Use HTTPS for Nominatim
  use_https: true,

  # Timeout and retry settings
  timeout: 5,

  # Don't raise exceptions on lookup failure — graceful degradation
  always_raise: []
)
