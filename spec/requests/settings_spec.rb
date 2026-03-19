require "rails_helper"

RSpec.describe "Settings", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in_as(user) }

  describe "GET /settings" do
    it "returns 200" do
      get settings_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /settings" do
    it "updates account name" do
      patch settings_path, params: { account: { name: "Updated Name" } }
      expect(response).to redirect_to(settings_path)
      expect(account.reload.name).to eq("Updated Name")
    end
  end
end
