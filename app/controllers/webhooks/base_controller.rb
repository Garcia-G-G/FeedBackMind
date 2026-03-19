module Webhooks
  class BaseController < ActionController::API
    before_action :read_raw_body

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "Not found", code: "not_found" }, status: :not_found
    end

    rescue_from ActionDispatch::Http::Parameters::ParseError do
      render json: { error: "Invalid JSON" }, status: :bad_request
    end

    private

    def read_raw_body
      @raw_body = request.body.read
      request.body.rewind
    end

    def find_account_from_params!
      Account.find(params.require(:account_id))
    end

    def find_source_id(account, type)
      account.sources.find_by!(source_type: type, active: true).id
    end

    def render_accepted
      head :ok
    end

    def render_unauthorized
      render json: { error: "Invalid signature", code: "unauthorized" }, status: :unauthorized
    end
  end
end
