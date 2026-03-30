class SettingsController < ApplicationController
  include Authorizable
  before_action :authorize_owner!, only: [:change_plan, :remove_member, :invite_member, :regenerate_token]

  def show
    @account = current_account

    # Handle Stripe checkout return
    if params[:checkout] == "success" && params[:plan].present?
      plan = params[:plan]
      if %w[starter growth scale].include?(plan) && plan != current_account.plan
        current_account.update!(plan: plan)
        flash.now[:notice] = "Successfully upgraded to #{plan.titleize} plan!"
      end
    elsif params[:checkout] == "cancelled"
      flash.now[:alert] = "Plan change was cancelled."
    end
  end

  def regenerate_token
    current_account.regenerate_api_token!
    redirect_to settings_path, notice: "API token regenerated."
  end

  def update
    @account = current_account

    if @account.update(account_params)
      redirect_to settings_path, notice: 'Settings were successfully updated.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  def invite_member
    unless current_user.owner?
      redirect_to settings_path, alert: "Only owners can invite members."
      return
    end

    max_users = current_account.max_users
    current_count = current_account.users.count

    if max_users != Float::INFINITY && current_count >= max_users
      redirect_to settings_path, alert: "User limit reached for your plan (#{max_users}). Please upgrade."
      return
    end

    email = params[:email]&.strip&.downcase
    if email.blank? || !email.match?(Devise.email_regexp)
      redirect_to settings_path, alert: "Please enter a valid email address."
      return
    end

    domain = email.split("@").last&.downcase
    if EmailDomainValidatable::TYPO_CORRECTIONS.key?(domain)
      corrected = email.sub(/@.*\z/, "@#{EmailDomainValidatable::TYPO_CORRECTIONS[domain]}")
      redirect_to settings_path, alert: "That email looks like a typo. Did you mean #{corrected}?"
      return
    end

    if current_account.users.exists?(email: email)
      redirect_to settings_path, alert: "This user is already a member."
      return
    end

    temp_password = SecureRandom.hex(16)
    user = current_account.users.build(
      email: email,
      name: email.split("@").first.titleize,
      password: temp_password,
      password_confirmation: temp_password,
      role: :member
    )

    if user.save
      user.send_reset_password_instructions
      redirect_to settings_path, notice: "Invitation sent to #{email}."
    else
      redirect_to settings_path, alert: "Could not invite user: #{user.errors.full_messages.join(', ')}"
    end
  end

  def remove_member
    unless current_user.owner?
      redirect_to settings_path, alert: "Only owners can remove members."
      return
    end

    member = current_account.users.find(params[:user_id])

    if member == current_user
      redirect_to settings_path, alert: "You cannot remove yourself."
      return
    end

    member.destroy
    redirect_to settings_path, notice: "Team member removed."
  end

  def dismiss_checklist
    current_user.update!(checklist_dismissed_at: Time.current)
    redirect_back fallback_location: dashboard_path
  end

  def bulk_priority
    BulkPriorityScoringJob.perform_async(current_account.id)
    redirect_to settings_path, notice: "Priority scoring started! Feedbacks will be scored in the background."
  end

  def change_plan
    plan = params[:plan]
    Rails.logger.info "[Stripe] change_plan called with plan=#{plan}"

    unless %w[starter growth scale].include?(plan)
      redirect_to settings_path, alert: "Invalid plan."
      return
    end

    if plan == current_account.plan
      redirect_to settings_path, notice: "You're already on the #{plan.titleize} plan."
      return
    end

    # If Stripe is configured, create a checkout session
    if ENV["STRIPE_SECRET_KEY"].present?
      Rails.logger.info "[Stripe] STRIPE_SECRET_KEY is present, creating checkout session"
      price_id = case plan
                 when "starter" then ENV["STRIPE_STARTER_PRICE_ID"]
                 when "growth" then ENV["STRIPE_GROWTH_PRICE_ID"]
                 when "scale" then ENV["STRIPE_SCALE_PRICE_ID"]
                 end

      Rails.logger.info "[Stripe] Price ID for #{plan}: #{price_id.present? ? price_id : 'MISSING'}"

      if price_id.present?
        begin
          base_url = request.base_url
          session = Stripe::Checkout::Session.create(
            mode: "subscription",
            customer_email: current_user.email,
            line_items: [{ price: price_id, quantity: 1 }],
            success_url: "#{base_url}/settings?checkout=success&plan=#{plan}",
            cancel_url: "#{base_url}/settings?checkout=cancelled",
            metadata: { account_id: current_account.id, plan: plan }
          )
          Rails.logger.info "[Stripe] Checkout session created, redirecting to: #{session.url}"
          redirect_to session.url, allow_other_host: true
          return
        rescue Stripe::StripeError => e
          Rails.logger.error("[Stripe] Checkout error: #{e.message}")
          redirect_to settings_path, alert: "Payment setup failed: #{e.message}"
          return
        rescue => e
          Rails.logger.error("[Stripe] Unexpected error: #{e.class} - #{e.message}")
          redirect_to settings_path, alert: "Payment error: #{e.message}"
          return
        end
      else
        Rails.logger.warn "[Stripe] No price ID found for plan=#{plan}, falling back to direct change"
      end
    else
      Rails.logger.warn "[Stripe] STRIPE_SECRET_KEY not set, falling back to direct change"
    end

    # Fallback: direct plan change (for development/demo without Stripe)
    current_account.update!(plan: plan)
    redirect_to settings_path, notice: "Plan changed to #{plan.titleize}."
  end

  private

  def account_params
    params.require(:account).permit(:name, :subdomain, :plan, :slack_webhook_url)
  end
end
