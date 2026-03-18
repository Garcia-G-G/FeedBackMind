module Api
  module V1
    class BaseController < ActionController::API
      include ApiAuthenticatable
      include Paginatable

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: "Not found", code: "not_found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: e.message, code: "validation_error" }, status: :unprocessable_entity
      end

      rescue_from ActionController::ParameterMissing do |e|
        render json: { error: e.message, code: "missing_parameter" }, status: :unprocessable_entity
      end
    end
  end
end
