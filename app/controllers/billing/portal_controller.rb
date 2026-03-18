module Billing
  class PortalController < ApplicationController
    before_action :authenticate_user!

    # POST /billing/portal
    def create
      result = Billing::CreatePortalSession.new(
        account: current_user.account,
        return_url: params[:return_url] || root_url
      ).call

      render json: { portal_url: result.url }
    end
  end
end
