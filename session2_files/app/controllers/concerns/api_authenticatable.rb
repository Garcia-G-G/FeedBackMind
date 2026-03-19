module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_token!
    before_action :set_current_tenant
  end

  private

  def authenticate_api_token!
    token = extract_bearer_token
    @current_account = Account.find_by(api_token: token)

    unless @current_account
      render json: { error: "Invalid or missing API token", code: "unauthorized" }, status: :unauthorized
    end
  end

  def extract_bearer_token
    header = request.headers["Authorization"]
    return nil unless header&.start_with?("Bearer ")
    header.split(" ").last
  end

  def set_current_tenant
    ActsAsTenant.current_tenant = @current_account
  end

  def current_account
    @current_account
  end
end
