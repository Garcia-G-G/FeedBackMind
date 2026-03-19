class Api::V1::Billing::PortalController < Api::V1::BaseController
  def create
    result = ::Billing::CreatePortalSession.new(
      account: current_account,
      return_url: params[:return_url] || root_url
    ).call

    render json: result, status: :created
  rescue => e
    render json: { error: e.message, code: "billing_error" }, status: :unprocessable_entity
  end
end
