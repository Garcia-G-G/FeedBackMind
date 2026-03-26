class OnboardingController < ApplicationController
  before_action :redirect_if_onboarded
  layout "onboarding"

  def show
    if params[:checkout] == "success" && params[:plan].present?
      plan = params[:plan]
      if %w[growth scale].include?(plan)
        current_account.update!(plan: plan)
        current_user.update!(onboarding_step: 2)
        redirect_to onboarding_path
        return
      end
    elsif params[:checkout] == "cancelled"
      flash.now[:alert] = "Payment was cancelled. You can select a different plan or try again."
    end

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
    unless plan.present? && %w[starter growth scale].include?(plan)
      @step = 1
      flash.now[:alert] = "Please select a plan to continue."
      render :show, status: :unprocessable_entity
      return
    end

    if plan == "starter"
      current_account.update!(plan: plan)
      current_user.update!(onboarding_step: 2)
      redirect_to onboarding_path
      return
    end

    if ENV["STRIPE_SECRET_KEY"].present?
      price_id = case plan
                 when "growth" then ENV["STRIPE_GROWTH_PRICE_ID"]
                 when "scale" then ENV["STRIPE_SCALE_PRICE_ID"]
                 end

      if price_id.present?
        begin
          base_url = "https://#{ENV.fetch('APP_HOST', '5.161.238.195.sslip.io')}"
          checkout_session = Stripe::Checkout::Session.create(
            mode: "subscription",
            customer_email: current_user.email,
            line_items: [{ price: price_id, quantity: 1 }],
            success_url: "#{base_url}/onboarding?checkout=success&plan=#{plan}",
            cancel_url: "#{base_url}/onboarding?checkout=cancelled",
            metadata: { account_id: current_account.id, plan: plan }
          )
          redirect_to checkout_session.url, allow_other_host: true
          return
        rescue Stripe::StripeError => e
          Rails.logger.error("[Stripe] Onboarding checkout error: #{e.message}")
          flash.now[:alert] = "Payment setup failed: #{e.message}"
          @step = 1
          render :show, status: :unprocessable_entity
          return
        rescue => e
          Rails.logger.error("[Stripe] Unexpected error: #{e.class} - #{e.message}")
        end
      end
    end

    Rails.logger.warn "[Stripe] Falling back to direct plan change"
    current_account.update!(plan: plan)
    current_user.update!(onboarding_step: 2)
    redirect_to onboarding_path
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
