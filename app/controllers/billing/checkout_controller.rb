module Billing
  class CheckoutController < ApplicationController
    before_action :authenticate_user!

    # POST /billing/checkout
    def create
      result = Billing::CreateCheckout.new(
        account: current_user.account,
        plan: params[:plan],
        success_url: params[:success_url] || root_url,
        cancel_url: params[:cancel_url] || root_url
      ).call

      render json: { checkout_url: result.url }
    end
  end
end
