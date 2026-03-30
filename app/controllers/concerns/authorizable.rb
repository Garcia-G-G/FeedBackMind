module Authorizable
  extend ActiveSupport::Concern

  private

  def authorize_owner!
    unless current_user&.owner?
      redirect_to root_path, alert: "Not authorized. Owner access required."
    end
  end
end
