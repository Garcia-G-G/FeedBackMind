module NpsCors
  extend ActiveSupport::Concern

  included do
    skip_forgery_protection if respond_to?(:skip_forgery_protection)
    before_action :set_cors_headers
  end

  private

  def set_cors_headers
    origin = request.headers["Origin"]

    if origin.present? && origin_allowed?(origin)
      response.headers["Access-Control-Allow-Origin"] = origin
      response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "Content-Type"
      response.headers["Vary"] = "Origin"
    end

    head(:ok) if request.method == "OPTIONS"
  end

  def origin_allowed?(origin)
    token = params[:token]
    return true if token.blank? # config endpoint without token — allow for initial load

    survey = NpsSurvey.find_by(survey_token: token)
    return true unless survey

    # If no allowed_origins set, allow all (backward compatible)
    return true if survey.allowed_origins.blank?

    allowed = survey.allowed_origins.split(",").map(&:strip)
    allowed.any? { |allowed_origin| origin == allowed_origin }
  end
end
