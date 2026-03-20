class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  layout false, only: [:home]

  def home
    redirect_to dashboard_path and return if user_signed_in?
  end
end
