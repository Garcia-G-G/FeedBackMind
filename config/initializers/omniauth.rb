Rails.application.config.middleware.use OmniAuth::Builder do
  provider :slack_openid,
    ENV.fetch("SLACK_CLIENT_ID", ""),
    ENV.fetch("SLACK_CLIENT_SECRET", ""),
    scope: "openid,email,profile"

  provider :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID", ""),
    ENV.fetch("GOOGLE_CLIENT_SECRET", ""),
    scope: "email,profile,https://www.googleapis.com/auth/gmail.readonly",
    access_type: "offline",
    prompt: "consent"
end

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true
