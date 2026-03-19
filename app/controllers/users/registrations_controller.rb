class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  def build_resource(hash = {})
    # Create an account for the new user automatically
    account = Account.create!(
      name: hash[:name].presence || hash[:email]&.split("@")&.first&.titleize || "My Team",
      subdomain: generate_subdomain(hash[:email])
    )

    super
    resource.account = account
    resource.role = :owner
  end

  def after_sign_up_path_for(resource)
    onboarding_path
  end

  private

  def generate_subdomain(email)
    base = email&.split("@")&.first&.parameterize || SecureRandom.hex(4)
    subdomain = base
    counter = 1
    while Account.exists?(subdomain: subdomain)
      subdomain = "#{base}-#{counter}"
      counter += 1
    end
    subdomain
  end
end
