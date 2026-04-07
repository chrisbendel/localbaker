if Rails.env.production?
  Geocoder.configure(
    lookup: :nominatim,
    http_headers: {
      user_agent: "LocalBaker (https://localbaker.app)"
    },
    cache: Rails.cache,
    cache_prefix: "geocoder:",
    use_https: true,
    timeout: 5,
    always_raise: []
  )
else
  # Use test lookup in dev/test — no network calls, returns stubs or empty results.
  # test_helper.rb sets a default stub for test; dev geocoding is mocked in GeocodeStoreJob.
  Geocoder.configure(lookup: :test, ip_lookup: :test)
end
