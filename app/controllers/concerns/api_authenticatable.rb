module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_token!
    before_action :set_current_tenant
  end

  private

  def authenticate_api_token!
    token = extract_token
    unless token
      render json: { error: "API token required", code: "unauthorized" }, status: :unauthorized
      return
    end

    account = Account.find_by(api_token: token)
    if account && ActiveSupport::SecurityUtils.secure_compare(account.api_token.to_s, token)
      @current_account = account
    else
      render json: { error: "Invalid API token", code: "unauthorized" }, status: :unauthorized
    end
  end

  def extract_token
    # Accept token via Authorization: Bearer <token> or X-Api-Key header
    auth_header = request.headers["Authorization"]
    if auth_header&.start_with?("Bearer ")
      auth_header.split(" ").last
    else
      request.headers["X-Api-Key"]
    end
  end

  def set_current_tenant
    ActsAsTenant.current_tenant = @current_account
  end

  def current_account
    @current_account
  end
end
