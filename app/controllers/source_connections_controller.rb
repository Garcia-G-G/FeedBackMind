class SourceConnectionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:omniauth_callback, :omniauth_failure]
  before_action :authenticate_user!, only: [:omniauth_callback], unless: -> { current_user.present? }

  # POST /sources/connect/:provider — redirect to OAuth provider
  def create
    provider = params[:provider]
    session[:return_to_onboarding] = true if params[:return_to] == "onboarding"

    case provider
    when "slack"
      if ENV["SLACK_CLIENT_ID"].blank?
        redirect_to sources_path, alert: "Slack is not configured yet. Please set SLACK_CLIENT_ID and SLACK_CLIENT_SECRET."
        return
      end
      redirect_to "/auth/slack_openid", allow_other_host: true
    when "gmail"
      if ENV["GOOGLE_CLIENT_ID"].blank?
        redirect_to sources_path, alert: "Gmail is not configured yet. Please set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET."
        return
      end
      redirect_to "/auth/google_oauth2", allow_other_host: true
    when "jira"
      if ENV["JIRA_CLIENT_ID"].blank?
        redirect_to sources_path, alert: "Jira is not configured yet. Please set JIRA_CLIENT_ID and JIRA_CLIENT_SECRET."
        return
      end
      redirect_to jira_auth_url, allow_other_host: true
    when "typeform"
      if ENV["TYPEFORM_CLIENT_ID"].blank?
        redirect_to sources_path, alert: "Typeform is not configured yet. Please set TYPEFORM_CLIENT_ID and TYPEFORM_CLIENT_SECRET."
        return
      end
      redirect_to typeform_auth_url, allow_other_host: true
    else
      redirect_to sources_path, alert: "Unknown provider: #{provider}"
    end
  end

  # GET /auth/:provider/callback — OmniAuth callback (Slack, Gmail)
  def omniauth_callback
    auth = request.env["omniauth.auth"]
    unless auth
      redirect_to sources_path, alert: "Authentication failed."
      return
    end

    unless current_user
      redirect_to new_user_session_path, alert: "Your session expired. Please sign in and try connecting again."
      return
    end

    source_type = case auth.provider
                  when "slack_openid" then :slack
                  when "google_oauth2" then :gmail
                  else auth.provider.to_sym
                  end

    source = current_account.sources.find_or_initialize_by(source_type: source_type)
    source.active = true
    source.config = (source.config || {}).merge(
      "access_token" => auth.credentials.token,
      "refresh_token" => auth.credentials.refresh_token,
      "uid" => auth.uid,
      "name" => auth.info.name || auth.info.email
    )
    source.save!

    # Return to onboarding if that's where the user came from
    origin = request.env["omniauth.origin"]
    if origin&.include?("/onboarding") || session.delete(:return_to_onboarding)
      redirect_to onboarding_path, notice: "#{source_type.to_s.titleize} connected!"
    else
      redirect_to sources_path, notice: "#{source_type.to_s.titleize} connected successfully!"
    end
  end

  # GET /auth/failure
  def omniauth_failure
    message = params[:message]
    detail = case message
             when /redirect_uri_mismatch/
               "Redirect URI mismatch. The callback URL configured in the provider dashboard must match: #{request.base_url}/auth/*/callback"
             when /invalid_client/
               "Invalid OAuth client. Please verify the client ID and secret are correct in your provider's developer console."
             when /access_denied/
               "Access denied. If using Google, ensure the OAuth consent screen is published (not in Testing mode) or add your email as a test user."
             else
               message
             end

    return_path = session.delete(:return_to_onboarding) ? onboarding_path : sources_path
    redirect_to return_path, alert: "Authentication failed: #{detail}"
  end

  # GET /sources/callback/jira
  def jira_callback
    token = exchange_code_for_token(
      token_url: "https://auth.atlassian.com/oauth/token",
      client_id: ENV.fetch("JIRA_CLIENT_ID", ""),
      client_secret: ENV.fetch("JIRA_CLIENT_SECRET", ""),
      code: params[:code],
      redirect_uri: jira_callback_sources_url
    )

    save_source(:jira, token)
    if session.delete(:return_to_onboarding)
      redirect_to onboarding_path, notice: "Jira connected!"
    else
      redirect_to sources_path, notice: "Jira connected successfully!"
    end
  rescue => e
    if session.delete(:return_to_onboarding)
      redirect_to onboarding_path, alert: "Jira connection failed: #{e.message}"
    else
      redirect_to sources_path, alert: "Jira connection failed: #{e.message}"
    end
  end

  # GET /sources/callback/typeform
  def typeform_callback
    token = exchange_code_for_token(
      token_url: "https://api.typeform.com/oauth/token",
      client_id: ENV.fetch("TYPEFORM_CLIENT_ID", ""),
      client_secret: ENV.fetch("TYPEFORM_CLIENT_SECRET", ""),
      code: params[:code],
      redirect_uri: typeform_callback_sources_url
    )

    save_source(:typeform, token)
    if session.delete(:return_to_onboarding)
      redirect_to onboarding_path, notice: "Typeform connected!"
    else
      redirect_to sources_path, notice: "Typeform connected successfully!"
    end
  rescue => e
    redirect_to sources_path, alert: "Typeform connection failed: #{e.message}"
  end

  # POST /sources/import_csv
  def import_csv
    file = params[:file]
    unless file.present?
      redirect_to new_source_path, alert: "Please select a CSV file."
      return
    end

    source = current_account.sources.find_or_create_by!(source_type: :csv) do |s|
      s.active = true
      s.config = {}
    end

    result = Feedbacks::CsvImporter.new(
      account: current_account,
      source: source,
      file: file
    ).import

    if result[:errors].any?
      redirect_to new_source_path, alert: "Import completed with errors: #{result[:errors].first}"
    else
      redirect_to sources_path, notice: "CSV imported: #{result[:enqueued]} feedbacks queued, #{result[:skipped]} skipped."
    end
  end

  private

  def save_source(source_type, token_data)
    source = current_account.sources.find_or_initialize_by(source_type: source_type)
    source.active = true
    source.config = (source.config || {}).merge(
      "access_token" => token_data["access_token"],
      "refresh_token" => token_data["refresh_token"],
      "token_type" => token_data["token_type"]
    )
    source.save!
  end

  def exchange_code_for_token(token_url:, client_id:, client_secret:, code:, redirect_uri:)
    response = Net::HTTP.post(
      URI(token_url),
      URI.encode_www_form(
        grant_type: "authorization_code",
        client_id: client_id,
        client_secret: client_secret,
        code: code,
        redirect_uri: redirect_uri
      ),
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept" => "application/json"
    )
    JSON.parse(response.body)
  end

  def jira_auth_url
    params = {
      audience: "api.atlassian.com",
      client_id: ENV.fetch("JIRA_CLIENT_ID", ""),
      scope: "read:jira-work write:jira-work read:jira-user",
      redirect_uri: jira_callback_sources_url,
      state: form_authenticity_token,
      response_type: "code",
      prompt: "consent"
    }
    "https://auth.atlassian.com/authorize?#{params.to_query}"
  end

  def typeform_auth_url
    params = {
      client_id: ENV.fetch("TYPEFORM_CLIENT_ID", ""),
      redirect_uri: typeform_callback_sources_url,
      scope: "responses:read forms:read webhooks:read webhooks:write",
      state: form_authenticity_token
    }
    "https://api.typeform.com/oauth/authorize?#{params.to_query}"
  end

  def jira_callback_sources_url
    url_for(controller: "source_connections", action: "jira_callback", only_path: false)
  end

  def typeform_callback_sources_url
    url_for(controller: "source_connections", action: "typeform_callback", only_path: false)
  end
end
