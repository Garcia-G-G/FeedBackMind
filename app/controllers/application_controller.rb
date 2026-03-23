class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :authenticate_user!
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :check_onboarding

  helper_method :current_account

  private

  def set_tenant
    ActsAsTenant.current_tenant = current_user&.account
  end

  def current_account
    ActsAsTenant.current_tenant
  end

  def check_onboarding
    return unless user_signed_in?
    return if controller_name == "onboarding"
    return if devise_controller?
    return if controller_name == "pages"
    return if current_user.onboarding_completed_at.present?
    redirect_to onboarding_path
  end
end
