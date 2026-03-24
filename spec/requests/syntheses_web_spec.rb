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
    it "enqueues synthesis job when conditions are met" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("sk-test-key")
      source = create(:source, account: account, source_type: :slack, active: true)
      create(:feedback, account: account, source: source, processed_at: Time.current, received_at: 1.day.ago)

      post syntheses_path
      expect(response).to redirect_to(syntheses_path)
      expect(WeeklySynthesisJob.jobs.size).to eq(1)
    end

    it "rejects when OPENAI_API_KEY is missing" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(nil)

      post syntheses_path
      expect(response).to redirect_to(syntheses_path)
      follow_redirect!
      expect(response.body).to include("OpenAI API key")
    end
  end
end
