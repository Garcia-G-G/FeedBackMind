class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  set_current_tenant_through_filter
  before_action :set_tenant

  helper_method :current_account

  private

  def set_tenant
    ActsAsTenant.current_tenant = current_user&.account
  end

  def current_account
    ActsAsTenant.current_tenant
  end
end
