class Webhooks::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :store_raw_body

  private

  def store_raw_body
    @raw_body = request.body.read
    request.body.rewind
  end

  def render_accepted
    render json: { status: "accepted" }, status: :ok
  end

  def render_unauthorized
    render json: { error: "Invalid signature", code: "unauthorized" }, status: :unauthorized
  end

  def find_account!(identifier)
    account = Account.find_by!(id: identifier)
    ActsAsTenant.current_tenant = account
    account
  end
end
