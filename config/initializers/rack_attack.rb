Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

# Throttle sign-in attempts by IP
Rack::Attack.throttle("logins/ip", limit: 10, period: 60.seconds) do |req|
  req.ip if req.path == "/users/sign_in" && req.post?
end

# Throttle sign-up attempts by IP
Rack::Attack.throttle("registrations/ip", limit: 5, period: 60.seconds) do |req|
  req.ip if req.path == "/users" && req.post?
end

# Throttle chat by IP (expensive OpenAI calls)
Rack::Attack.throttle("chat/ip", limit: 20, period: 60.seconds) do |req|
  req.ip if req.path == "/chat" && req.post?
end

# Throttle API endpoints by token
Rack::Attack.throttle("api/token", limit: 60, period: 60.seconds) do |req|
  if req.path.start_with?("/api/")
    req.env["HTTP_AUTHORIZATION"]&.split(" ")&.last || req.env["HTTP_X_API_KEY"]
  end
end

# Throttle webhooks by IP
Rack::Attack.throttle("webhooks/ip", limit: 120, period: 60.seconds) do |req|
  req.ip if req.path.start_with?("/webhooks/")
end

# Throttle password reset by IP
Rack::Attack.throttle("password_reset/ip", limit: 5, period: 300.seconds) do |req|
  req.ip if req.path == "/users/password" && req.post?
end

# Custom response for throttled requests
Rack::Attack.throttled_responder = lambda do |_request|
  [429, { "Content-Type" => "application/json" }, [{ error: "Rate limit exceeded. Please try again later." }.to_json]]
end
