require "rails_helper"

RSpec.describe "Syntheses (Web)", type: :request do
  let(:account) { create(:account, :growth) }
  let(:user) { create(:user, account: account) }

  before { sign_in_as(user) }

  describe "GET /syntheses" do
    it "returns 200" do
      get syntheses_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /syntheses/:id" do
    it "shows a synthesis" do
      synthesis = create(:weekly_synthesis, account: account)
      get synthesis_path(synthesis)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /syntheses" do
    it "enqueues synthesis job and redirects" do
      post syntheses_path
      expect(response).to redirect_to(syntheses_path)
      expect(WeeklySynthesisJob.jobs.size).to eq(1)
    end
  end
end
