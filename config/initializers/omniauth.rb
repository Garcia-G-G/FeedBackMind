# OmniAuth configuration for SOURCE CONNECTIONS (Slack, Gmail).
# This is SEPARATE from Devise's OmniAuth (used for user login with Google).
#
# IMPORTANT: Devise changes OmniAuth.config.path_prefix to "/users/auth" globally.
# We must set path_prefix: "/auth" explicitly on each provider here so they
# respond at /auth/slack_openid and /auth/google_gmail (not /users/auth/...).

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :slack_openid,
    ENV.fetch("SLACK_CLIENT_ID", ""),
    ENV.fetch("SLACK_CLIENT_SECRET", ""),
    scope: "openid,email,profile",
    path_prefix: "/auth"

  # Gmail source connection — uses name: "google_gmail" to avoid conflict
  # with Devise's google_oauth2 provider (used for user login).
  provider :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID", ""),
    ENV.fetch("GOOGLE_CLIENT_SECRET", ""),
    scope: "email,profile,https://www.googleapis.com/auth/gmail.readonly",
    access_type: "offline",
    prompt: "consent",
    name: "google_gmail",
    path_prefix: "/auth"
end

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true
