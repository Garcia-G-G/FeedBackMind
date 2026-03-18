module Api
  module V1
    class AccountsController < BaseController
      # GET /api/v1/account
      def show
        render json: account_json(current_account)
      end

      # PATCH /api/v1/account
      def update
        current_account.update!(account_params)
        render json: account_json(current_account)
      end

      # POST /api/v1/account/regenerate_token
      def regenerate_token
        current_account.regenerate_api_token!
        render json: { api_token: current_account.api_token }
      end

      private

      def account_params
        params.require(:account).permit(:name)
      end

      def account_json(account)
        {
          id: account.id,
          name: account.name,
          subdomain: account.subdomain,
          plan: account.plan,
          feedback_count_this_month: account.feedback_count_this_month,
          plan_limits: account.plan_limits,
          created_at: account.created_at
        }
      end
    end
  end
end
