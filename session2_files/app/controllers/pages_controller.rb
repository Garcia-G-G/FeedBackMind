class PagesController < ApplicationController
  def home
    if user_signed_in?
      redirect_to api_v1_account_path(format: :json)
    else
      render plain: "FeedbackMind API — Visit /api/v1/ with a valid Bearer token."
    end
  end
end
