require "rails_helper"

RSpec.describe "Api::V1::Chat", type: :request do
  let(:account) { create(:account, :growth) }
  let(:user) { create(:user, account: account) }

  describe "POST /api/v1/chat_messages" do
    it "rejects chat on starter plan" do
      starter_account = create(:account, plan: :starter)
      starter_user = create(:user, account: starter_account)

      post "/api/v1/chat_messages",
           params: { message: "What features did users request?", user_id: starter_user.id }.to_json,
           headers: api_headers(starter_account)

      expect(response).to have_http_status(:forbidden)
      expect(json_response["code"]).to eq("plan_limit")
    end
  end
end
