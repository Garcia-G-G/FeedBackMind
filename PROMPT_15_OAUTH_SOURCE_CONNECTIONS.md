# PROMPT 15 — OAuth Source Connections (Make Sources REAL)

Users need to actually connect their Intercom, Slack, Gmail, Jira, and Typeform accounts. Implement OAuth flows for each source type.

## Overview
When a user clicks "Add Source" and picks a type, they should be redirected to the OAuth authorization URL. After authorizing, they come back to our callback URL and we save the access token in the source's `config` JSONB column.

## Task 1: Add OmniAuth gems to Gemfile

Add these gems:
```ruby
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "omniauth-slack-openid", "~> 1.2"    # Slack OAuth v2
gem "omniauth-google-oauth2", "~> 1.1"    # Gmail via Google
gem "oauth2", "~> 2.0"                     # For custom OAuth flows (Intercom, Jira, Typeform)
```

Run `bundle install`.

## Task 2: Create OmniAuth initializer

Create `config/initializers/omniauth.rb`:
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  # Slack
  provider :slack_openid,
    ENV["SLACK_CLIENT_ID"],
    ENV["SLACK_CLIENT_SECRET"],
    scope: "openid,channels:history,groups:history,im:history,mpim:history,channels:read"

  # Google (Gmail)
  provider :google_oauth2,
    ENV["GOOGLE_CLIENT_ID"],
    ENV["GOOGLE_CLIENT_SECRET"],
    scope: "email,https://www.googleapis.com/auth/gmail.readonly",
    access_type: "offline",
    prompt: "consent"
end

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true
```

## Task 3: Create SourceConnectionsController

This controller handles the OAuth callback and source creation:

```ruby
# app/controllers/source_connections_controller.rb
class SourceConnectionsController < ApplicationController
  # POST /sources/connect/:provider — initiates OAuth
  def create
    provider = params[:provider]
    case provider
    when "intercom"
      redirect_to intercom_oauth_url, allow_other_host: true
    when "jira"
      redirect_to jira_oauth_url, allow_other_host: true
    when "typeform"
      redirect_to typeform_oauth_url, allow_other_host: true
    else
      # Slack and Gmail use OmniAuth — redirect to /auth/:provider
      redirect_to "/auth/#{provider}"
    end
  end

  # GET /auth/:provider/callback — OmniAuth callback (Slack, Google)
  def omniauth_callback
    auth = request.env["omniauth.auth"]
    provider = auth.provider

    source_type = case provider
                  when "slack_openid" then "slack"
                  when "google_oauth2" then "gmail"
                  else provider
                  end

    source = current_account.sources.find_or_initialize_by(source_type: source_type)
    source.name = "#{source_type.titleize} — #{auth.info.name || auth.info.email}"
    source.active = true
    source.config = {
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token,
      expires_at: auth.credentials.expires_at,
      uid: auth.uid,
      email: auth.info.email
    }

    if source.save
      redirect_to sources_path, notice: "#{source_type.titleize} connected successfully!"
    else
      redirect_to sources_path, alert: "Failed to connect: #{source.errors.full_messages.join(', ')}"
    end
  end

  # GET /auth/failure — OmniAuth failure
  def omniauth_failure
    redirect_to sources_path, alert: "Authentication failed: #{params[:message]}"
  end

  # GET /sources/callback/intercom — Custom OAuth callback
  def intercom_callback
    code = params[:code]
    token_response = exchange_intercom_token(code)

    if token_response
      source = current_account.sources.find_or_initialize_by(source_type: :intercom)
      source.name = "Intercom"
      source.active = true
      source.config = { access_token: token_response["access_token"] }
      source.save!
      redirect_to sources_path, notice: "Intercom connected!"
    else
      redirect_to sources_path, alert: "Intercom connection failed."
    end
  end

  # GET /sources/callback/jira — Jira OAuth callback
  def jira_callback
    code = params[:code]
    token_response = exchange_jira_token(code)

    if token_response
      source = current_account.sources.find_or_initialize_by(source_type: :jira)
      source.name = "Jira"
      source.active = true
      source.config = {
        access_token: token_response["access_token"],
        refresh_token: token_response["refresh_token"],
        cloud_id: fetch_jira_cloud_id(token_response["access_token"])
      }
      source.save!
      redirect_to sources_path, notice: "Jira connected!"
    else
      redirect_to sources_path, alert: "Jira connection failed."
    end
  end

  # GET /sources/callback/typeform — Typeform OAuth callback
  def typeform_callback
    code = params[:code]
    token_response = exchange_typeform_token(code)

    if token_response
      source = current_account.sources.find_or_initialize_by(source_type: :typeform)
      source.name = "Typeform"
      source.active = true
      source.config = {
        access_token: token_response["access_token"],
        refresh_token: token_response["refresh_token"]
      }
      source.save!
      redirect_to sources_path, notice: "Typeform connected!"
    else
      redirect_to sources_path, alert: "Typeform connection failed."
    end
  end

  private

  def intercom_oauth_url
    "https://app.intercom.com/oauth?client_id=#{ENV['INTERCOM_CLIENT_ID']}&redirect_uri=#{CGI.escape(intercom_callback_url)}"
  end

  def intercom_callback_url
    "#{request.base_url}/sources/callback/intercom"
  end

  def exchange_intercom_token(code)
    response = Net::HTTP.post(
      URI("https://api.intercom.io/auth/eagle/token"),
      { client_id: ENV["INTERCOM_CLIENT_ID"], client_secret: ENV["INTERCOM_CLIENT_SECRET"], code: code }.to_json,
      "Content-Type" => "application/json"
    )
    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  end

  def jira_oauth_url
    params = {
      audience: "api.atlassian.com",
      client_id: ENV["JIRA_CLIENT_ID"],
      scope: "read:jira-work read:jira-user write:jira-work",
      redirect_uri: "#{request.base_url}/sources/callback/jira",
      response_type: "code",
      prompt: "consent"
    }
    "https://auth.atlassian.com/authorize?#{params.to_query}"
  end

  def exchange_jira_token(code)
    response = Net::HTTP.post(
      URI("https://auth.atlassian.com/oauth/token"),
      { grant_type: "authorization_code", client_id: ENV["JIRA_CLIENT_ID"], client_secret: ENV["JIRA_CLIENT_SECRET"], code: code, redirect_uri: "#{request.base_url}/sources/callback/jira" }.to_json,
      "Content-Type" => "application/json"
    )
    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  end

  def fetch_jira_cloud_id(token)
    response = Net::HTTP.get(URI("https://api.atlassian.com/oauth/token/accessible-resources"), { "Authorization" => "Bearer #{token}" })
    data = JSON.parse(response)
    data.first&.dig("id")
  rescue
    nil
  end

  def typeform_oauth_url
    params = {
      client_id: ENV["TYPEFORM_CLIENT_ID"],
      scope: "forms:read responses:read",
      redirect_uri: "#{request.base_url}/sources/callback/typeform"
    }
    "https://api.typeform.com/oauth/authorize?#{params.to_query}"
  end

  def exchange_typeform_token(code)
    response = Net::HTTP.post_form(
      URI("https://api.typeform.com/oauth/token"),
      {
        grant_type: "authorization_code",
        client_id: ENV["TYPEFORM_CLIENT_ID"],
        client_secret: ENV["TYPEFORM_CLIENT_SECRET"],
        code: code,
        redirect_uri: "#{request.base_url}/sources/callback/typeform"
      }
    )
    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  end
end
```

## Task 4: Add routes for OAuth

Add these routes to config/routes.rb inside the authenticated block:
```ruby
# OAuth source connections
post "sources/connect/:provider", to: "source_connections#create", as: :connect_source
get "sources/callback/intercom", to: "source_connections#intercom_callback"
get "sources/callback/jira", to: "source_connections#jira_callback"
get "sources/callback/typeform", to: "source_connections#typeform_callback"

# OmniAuth callbacks (outside authenticated block, but controller requires auth)
get "/auth/:provider/callback", to: "source_connections#omniauth_callback"
get "/auth/failure", to: "source_connections#omniauth_failure"
```

## Task 5: Update Sources index view

Update the sources/index.html.erb to show a "Connect" button for each source type that isn't connected yet. For connected sources, show status and disconnect option.

Add a connect source modal/page where the user picks which provider to connect:
- Intercom → OAuth redirect
- Slack → OAuth redirect
- Gmail → Google OAuth redirect
- Jira → OAuth redirect
- Typeform → OAuth redirect
- App Store → Manual setup (just enter App ID)
- CSV → File upload form

Each button should be a form with `button_to connect_source_path(provider: "slack"), method: :post`.

## Task 6: Update .env.example

Add all required OAuth credentials:
```
# Slack OAuth
SLACK_CLIENT_ID=
SLACK_CLIENT_SECRET=

# Google OAuth (Gmail)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Intercom OAuth
INTERCOM_CLIENT_ID=
INTERCOM_CLIENT_SECRET=

# Jira OAuth (Atlassian)
JIRA_CLIENT_ID=
JIRA_CLIENT_SECRET=

# Typeform OAuth
TYPEFORM_CLIENT_ID=
TYPEFORM_CLIENT_SECRET=
```

## Task 7: CSV Import page

Create a dedicated CSV import page at `/sources/import_csv` with:
- File upload form (accepts .csv files)
- Column mapping instructions
- Preview of first 5 rows before import
- Submit triggers Feedbacks::CsvImporter service
- Show progress and results

## Verify
After implementing, all source connections should work:
1. Click "Add Source" → Select provider → Redirect to OAuth
2. After authorizing → Redirect back → Source appears as "Active"
3. CSV import → Upload file → Feedbacks created
