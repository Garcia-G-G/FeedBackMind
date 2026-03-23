class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def build_resource(hash = {})
    account = Account.create!(
      name: hash[:name].presence || hash[:email]&.split("@")&.first&.titleize || "My Team",
      subdomain: generate_subdomain(hash[:email]),
      plan: :starter
    )

    super
    resource.account = account
    resource.role = :owner
  rescue ActiveRecord::RecordInvalid => e
    super
    resource.errors.add(:base, "Could not create your workspace: #{e.message}")
  end

  def after_sign_up_path_for(resource)
    onboarding_path
  end

  private

  def generate_subdomain(email)
    base = email&.split("@")&.first&.parameterize.presence || SecureRandom.hex(4)
    base = "team-#{base}" if base.length < 3
    subdomain = base
    counter = 1
    while Account.exists?(subdomain: subdomain)
      subdomain = "#{base}-#{counter}"
      counter += 1
    end
    subdomain
  end
end
