class Rack::Attack
  # Throttle all requests by IP: 300 req / 5 min
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Throttle login attempts by IP: 10 req / 20 sec
  throttle("logins/ip", limit: 10, period: 20.seconds) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  # Return 429 for throttled requests
  self.throttled_responder = lambda do |req|
    [429, { "Content-Type" => "text/plain" }, ["Too many requests. Please try again later."]]
  end
end
