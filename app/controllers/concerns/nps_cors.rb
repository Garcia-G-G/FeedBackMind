module NpsCors
  extend ActiveSupport::Concern

  included do
    skip_forgery_protection
    before_action :set_cors_headers
  end

  private

  def set_cors_headers
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"

    head(:ok) if request.method == "OPTIONS"
  end
end
