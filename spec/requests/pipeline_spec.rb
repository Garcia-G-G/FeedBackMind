require "rails_helper"

RSpec.describe "Pipeline", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in_as(user) }

  describe "GET /pipeline" do
    it "returns 200" do
      get pipeline_path
      expect(response).to have_http_status(:ok)
    end
  end
end
