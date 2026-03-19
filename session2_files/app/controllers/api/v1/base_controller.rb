class Api::V1::BaseController < ApplicationController
  include ApiAuthenticatable
  include Paginatable

  skip_before_action :verify_authenticity_token
  before_action :set_default_format

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: "Record not found", code: "not_found" }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { error: e.message, code: "validation_error" }, status: :unprocessable_entity
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message, code: "missing_parameter" }, status: :bad_request
  end

  private

  def set_default_format
    request.format = :json unless params[:format]
  end
end
