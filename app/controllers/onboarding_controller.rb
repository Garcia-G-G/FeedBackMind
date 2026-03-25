class OnboardingController < ApplicationController
  before_action :redirect_if_onboarded
  layout "onboarding"

  def show
    @step = current_step
    @selected_plan = current_account.plan if @step == 1
  end

  def update
    if params[:back].present?
      go_back
      return
    end

    case current_step
    when 1 then select_plan
    when 2 then update_account_info
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

  def go_back
    new_step = [current_step - 1, 1].max
    current_user.update!(onboarding_step: new_step)
    redirect_to onboarding_path
  end

  def select_plan
    plan = params.dig(:account, :plan)
    if plan.present? && %w[starter growth scale].include?(plan)
      current_account.update!(plan: plan)
      current_user.update!(onboarding_step: 2)
      redirect_to onboarding_path
    else
      @step = 1
      flash.now[:alert] = "Please select a plan to continue."
      render :show, status: :unprocessable_entity
    end
  end

  def update_account_info
    if current_account.update(account_params)
      current_user.update!(onboarding_step: 3)
      redirect_to onboarding_path
    else
      @step = 2
      render :show, status: :unprocessable_entity
    end
  end

  def complete_onboarding
    if params[:selected_sources].present?
      params[:selected_sources].split(",").each do |source_type|
        next unless %w[slack gmail jira typeform appstore csv].include?(source_type)
        current_account.sources.find_or_create_by(source_type: source_type) do |src|
          src.active = false
          src.config = {}
        end
      end
    end

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
