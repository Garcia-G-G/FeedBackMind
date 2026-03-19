require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:account) { create(:account, :growth) }
  let(:user) { create(:user, account: account) }

  before { sign_in_as(user) }

  describe "GET /dashboard" do
    it "returns 200" do
      get dashboard_path
      expect(response).to have_http_status(:ok)
    end

    it "shows real feedback count" do
      source = create(:source, account: account)
      create_list(:feedback, 5, account: account, source: source, received_at: 1.day.ago)
      get dashboard_path
      expect(response.body).to include("5")
    end

    it "is not accessible without authentication" do
      sign_out user
      get "/dashboard"
      expect(response).not_to have_http_status(:ok)
    end

    it "accepts period parameter" do
      get dashboard_path(period: "30")
      expect(response).to have_http_status(:ok)
    end
  end
end
