class OnboardingController < ApplicationController
  before_action :redirect_if_onboarded
  layout "onboarding"

  def show
    @step = current_step
  end

  def update
    case current_step
    when 1 then update_account_info
    when 2 then update_sources
    when 3 then complete_onboarding
    else
      redirect_to onboarding_path
    end
  end

  private

  def current_step
    [current_user.onboarding_step || 0, 1].max
  end

  def redirect_if_onboarded
    redirect_to dashboard_path if current_user.onboarding_completed_at.present?
  end

  def update_account_info
    if current_account.update(account_params)
      current_user.update!(onboarding_step: 2)
      redirect_to onboarding_path
    else
      @step = 1
      render :show, status: :unprocessable_entity
    end
  end

  def update_sources
    # User either connected a source or skipped
    current_user.update!(onboarding_step: 3)
    redirect_to onboarding_path
  end

  def complete_onboarding
    current_user.update!(
      onboarding_completed_at: Time.current,
      onboarding_step: 3
    )
    redirect_to dashboard_path, notice: "Welcome to FeedbackMind! Your workspace is ready."
  end

  def account_params
    params.require(:account).permit(:name, :subdomain)
  end
end
