class Rack::Attack
  # Use Rails cache store for throttle data (prevents in-memory accumulation)
  cache.store = Rails.cache

  # Throttle all requests by IP: 300 req / 5 min
  throttle("req/ip", limit: 60, period: 1.minutes) do |req|
    req.ip
  end

  # Throttle login attempts by IP: 10 req / 20 sec
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  # Return 429 for throttled requests
  self.throttled_responder = lambda do |req|
    [429, {"Content-Type" => "text/plain"}, ["Too many requests. Please try again later."]]
  end

  # Block suspicious requests looking for WordPress/PHP
  blocklist("block wordpress") do |req|
    # Block any request containing WordPress patterns or ending in .php
    # These are high-confidence indicators of malicious/automated scanning
    req.path.include?("wp-admin") ||
      req.path.include?("wp-login") ||
      req.path.include?("wp-content") ||
      req.path.include?("wp-includes") ||
      req.path.include?("wordpress") ||
      req.path.match?(/\.php$/i)
  end
end
