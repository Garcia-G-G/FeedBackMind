require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET / (unauthenticated)" do
    it "returns 200 landing page" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("FeedbackMind")
    end
  end

  describe "GET / (authenticated)" do
    it "shows dashboard content" do
      account = create(:account)
      user = create(:user, account: account)
      sign_in user
      get root_path
      # Authenticated root renders dashboard#index directly
      expect(response).to have_http_status(:ok)
    end
  end
end
