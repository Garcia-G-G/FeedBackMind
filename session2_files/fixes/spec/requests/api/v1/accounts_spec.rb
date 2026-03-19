require "rails_helper"

RSpec.describe "Api::V1::Accounts", type: :request do
  let(:account) { create(:account, :with_stripe, plan: :growth) }
  let!(:user) { create(:user, account: account) }

  describe "GET /api/v1/account" do
    it "returns account details with valid token" do
      get "/api/v1/account", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(json_response["account"]["name"]).to eq(account.name)
      expect(json_response["account"]["plan"]).to eq("growth")
      expect(json_response["account"]["plan_limits"]).to be_present
    end

    it "returns 401 with invalid token" do
      get "/api/v1/account", headers: {
        "Authorization" => "Bearer invalid_token",
        "Content-Type" => "application/json"
      }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["error"]).to include("Invalid")
    end

    it "returns 401 with no token" do
      get "/api/v1/account", headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/account" do
    it "updates account name" do
      patch "/api/v1/account",
            params: { account: { name: "New Name" } }.to_json,
            headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(account.reload.name).to eq("New Name")
    end
  end
end
