# PROMPT 15 — OAuth Source Connections

Users need to connect their real accounts (Slack, Gmail, Intercom, Jira, Typeform). Implement OAuth flows.

## Task 1: Add gems
```ruby
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "omniauth-slack-openid", "~> 1.2"
gem "omniauth-google-oauth2", "~> 1.1"
gem "oauth2", "~> 2.0"
```
Run bundle install.

## Task 2: Create config/initializers/omniauth.rb
Configure OmniAuth with Slack (slack_openid) and Google (google_oauth2) providers using ENV vars.

## Task 3: Create SourceConnectionsController

Handle OAuth flows for all source types:
- POST /sources/connect/:provider → initiates OAuth (redirects to provider auth URL)
- GET /auth/:provider/callback → OmniAuth callback for Slack, Gmail
- GET /sources/callback/intercom → custom OAuth for Intercom
- GET /sources/callback/jira → custom OAuth for Jira (Atlassian)
- GET /sources/callback/typeform → custom OAuth for Typeform
- GET /auth/failure → error handling

On successful callback:
1. Find or create Source for current_account with the source_type
2. Save access_token, refresh_token, uid in source.config JSONB
3. Set source.active = true
4. Redirect to sources_path with success notice

For custom OAuth (Intercom, Jira, Typeform):
- Build authorization URL with client_id, redirect_uri, scopes
- Exchange authorization code for access_token via HTTP POST
- Save tokens in source config

## Task 4: Add routes
```ruby
# Inside authenticated block:
post "sources/connect/:provider", to: "source_connections#create", as: :connect_source
get "sources/callback/intercom", to: "source_connections#intercom_callback"
get "sources/callback/jira", to: "source_connections#jira_callback"
get "sources/callback/typeform", to: "source_connections#typeform_callback"

# Outside authenticated (OmniAuth middleware handles these):
get "/auth/:provider/callback", to: "source_connections#omniauth_callback"
get "/auth/failure", to: "source_connections#omniauth_failure"
```

## Task 5: Update sources/index.html.erb

Show connected sources with status. For unconnected types, show "Connect" button. Each connect button is a `button_to connect_source_path(provider: "slack"), method: :post`.

## Task 6: Create sources/new.html.erb as "Add Source" page

Grid of source type cards:
- Slack → OAuth button
- Gmail → Google OAuth button
- Intercom → OAuth button
- Jira → OAuth button
- Typeform → OAuth button
- App Store → Manual form (enter App ID)
- CSV → File upload form that posts to the CSV import endpoint

## Task 7: Update .env.example with all OAuth credentials placeholders

## Task 8: CSV Import page
Create a dedicated view for CSV import with file upload form, column mapping instructions, and submit button that triggers Feedbacks::CsvImporter.
