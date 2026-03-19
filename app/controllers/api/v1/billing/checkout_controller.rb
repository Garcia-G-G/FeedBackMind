class Api::V1::Billing::CheckoutController < Api::V1::BaseController
  def create
    plan = params.require(:plan)

    unless %w[starter growth scale].include?(plan)
      return render json: { error: "Invalid plan: #{plan}", code: "invalid_plan" }, status: :unprocessable_entity
    end

    result = ::Billing::CreateCheckout.new(
      account: current_account,
      plan: plan,
      success_url: params[:success_url] || root_url,
      cancel_url: params[:cancel_url] || root_url
    ).call

    render json: result, status: :created
  end
end
