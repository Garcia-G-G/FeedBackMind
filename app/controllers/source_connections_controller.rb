class SourceConnectionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:omniauth_callback, :omniauth_failure]
  before_action :authenticate_user!, only: [:omniauth_callback], unless: -> { current_user.present? }

  # POST /sources/connect/:provider — initiate OAuth flow
  def create
    provider = params[:provider]
    session[:return_to_onboarding] = true if params[:return_to] == "onboarding"

    Rails.logger.info "[OAuth] Connect request for provider=#{provider}"

    case provider
    when "slack"
      if ENV["SLACK_CLIENT_ID"].blank?
        redirect_to sources_path, alert: "Slack is not configured yet. Please set SLACK_CLIENT_ID and SLACK_CLIENT_SECRET."
        return
      end
      render_omniauth_form("/auth/slack_openid")
    when "gmail"
      if ENV["GOOGLE_CLIENT_ID"].blank?
        redirect_to sources_path, alert: "Gmail is not configured yet. Please set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET."
        return
      end
      render_omniauth_form("/auth/google_gmail")
    when "jira"
      if ENV["JIRA_CLIENT_ID"].blank?
        redirect_to sources_path, alert: "Jira is not configured yet. Please set JIRA_CLIENT_ID and JIRA_CLIENT_SECRET."
        return
      end
      auth_url = jira_auth_url
      Rails.logger.info "[OAuth] Jira auth URL: #{auth_url}"
      Rails.logger.info "[OAuth] Jira callback URL: #{jira_callback_url}"
      redirect_to auth_url, allow_other_host: true
    when "typeform"
      if ENV["TYPEFORM_CLIENT_ID"].blank?
        redirect_to sources_path, alert: "Typeform is not configured yet. Please set TYPEFORM_CLIENT_ID and TYPEFORM_CLIENT_SECRET."
        return
      end
      auth_url = typeform_auth_url
      Rails.logger.info "[OAuth] Typeform auth URL: #{auth_url}"
      Rails.logger.info "[OAuth] Typeform callback URL: #{typeform_callback_url}"
      redirect_to auth_url, allow_other_host: true
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
                  when "google_gmail" then :gmail
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
    Rails.logger.info "[OAuth] Jira callback received with code=#{params[:code].present?}"
    token = exchange_code_for_token(
      token_url: "https://auth.atlassian.com/oauth/token",
      client_id: ENV.fetch("JIRA_CLIENT_ID", ""),
      client_secret: ENV.fetch("JIRA_CLIENT_SECRET", ""),
      code: params[:code],
      redirect_uri: jira_callback_url
    )

    save_source(:jira, token)
    if session.delete(:return_to_onboarding)
      redirect_to onboarding_path, notice: "Jira connected!"
    else
      redirect_to sources_path, notice: "Jira connected successfully!"
    end
  rescue => e
    Rails.logger.error "[OAuth] Jira callback error: #{e.message}"
    error_msg = if e.message.include?("access_denied") || e.message.include?("forbidden")
      "Jira access denied. Verify the callback URL #{jira_callback_url} is configured in your Atlassian developer console."
    else
      "Jira connection failed: #{e.message}"
    end
    redirect_path = session.delete(:return_to_onboarding) ? onboarding_path : sources_path
    redirect_to redirect_path, alert: error_msg
  end

  # GET /sources/callback/typeform
  def typeform_callback
    Rails.logger.info "[OAuth] Typeform callback received with code=#{params[:code].present?}"
    token = exchange_code_for_token(
      token_url: "https://api.typeform.com/oauth/token",
      client_id: ENV.fetch("TYPEFORM_CLIENT_ID", ""),
      client_secret: ENV.fetch("TYPEFORM_CLIENT_SECRET", ""),
      code: params[:code],
      redirect_uri: typeform_callback_url
    )

    save_source(:typeform, token)
    if session.delete(:return_to_onboarding)
      redirect_to onboarding_path, notice: "Typeform connected!"
    else
      redirect_to sources_path, notice: "Typeform connected successfully!"
    end
  rescue => e
    Rails.logger.error "[OAuth] Typeform callback error: #{e.message}"
    error_msg = if e.message.include?("forbidden") || e.message.include?("403")
      "Typeform access denied. Verify the callback URL #{typeform_callback_url} is configured in your Typeform admin panel."
    else
      "Typeform connection failed: #{e.message}"
    end
    redirect_path = session.delete(:return_to_onboarding) ? onboarding_path : sources_path
    redirect_to redirect_path, alert: error_msg
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

  # Renders a self-submitting POST form to initiate OmniAuth flow.
  # OmniAuth requires POST for security (CSRF protection via omniauth-rails_csrf_protection).
  # A simple redirect_to would send a GET request, which OmniAuth rejects.
  def render_omniauth_form(path)
    token = form_authenticity_token
    render html: <<~HTML.html_safe, layout: false
      <!DOCTYPE html>
      <html>
        <body>
          <form id="omniauth-form" action="#{path}" method="post" style="display:none">
            <input type="hidden" name="authenticity_token" value="#{token}" />
          </form>
          <p style="font-family: sans-serif; text-align: center; margin-top: 100px; color: #78716c;">
            Redirecting to authentication provider...
          </p>
          <script>document.getElementById('omniauth-form').submit();</script>
        </body>
      </html>
    HTML
  end

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

  # Dynamic base URL — uses the current request's host, so it works
  # correctly in both development (localhost:3500) and production.
  def dynamic_base_url
    request.base_url
  end

  def jira_callback_url
    "#{dynamic_base_url}/sources/callback/jira"
  end

  def typeform_callback_url
    "#{dynamic_base_url}/sources/callback/typeform"
  end

  def jira_auth_url
    params = {
      audience: "api.atlassian.com",
      client_id: ENV.fetch("JIRA_CLIENT_ID", ""),
      scope: "read:jira-work write:jira-work read:jira-user",
      redirect_uri: jira_callback_url,
      state: form_authenticity_token,
      response_type: "code",
      prompt: "consent"
    }
    "https://auth.atlassian.com/authorize?#{params.to_query}"
  end

  def typeform_auth_url
    params = {
      client_id: ENV.fetch("TYPEFORM_CLIENT_ID", ""),
      redirect_uri: typeform_callback_url,
      scope: "responses:read forms:read webhooks:read webhooks:write",
      state: form_authenticity_token
    }
    "https://api.typeform.com/oauth/authorize?#{params.to_query}"
  end
end
