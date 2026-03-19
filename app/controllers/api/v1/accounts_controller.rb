class Api::V1::AccountsController < Api::V1::BaseController
  def show
    render json: {
      account: {
        id: current_account.id,
        name: current_account.name,
        subdomain: current_account.subdomain,
        plan: current_account.plan,
        feedback_count_this_month: current_account.feedback_count_this_month,
        plan_limits: current_account.plan_limits,
        feedback_limit_reached: current_account.feedback_limit_reached?,
        sources_count: current_account.sources.active.count,
        users_count: current_account.users.count,
        created_at: current_account.created_at
      }
    }
  end

  def update
    if current_account.update(account_params)
      render json: { account: current_account.slice(:id, :name, :subdomain) }, status: :ok
    else
      render json: { error: current_account.errors.full_messages.join(", "), code: "validation_error" }, status: :unprocessable_entity
    end
  end

  def regenerate_token
    current_account.regenerate_api_token!
    render json: { api_token: current_account.api_token }, status: :ok
  end

  private

  def account_params
    params.require(:account).permit(:name)
  end
end
