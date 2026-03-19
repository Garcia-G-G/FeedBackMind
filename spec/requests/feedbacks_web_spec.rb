require "rails_helper"

RSpec.describe "Feedbacks (Web)", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:source) { create(:source, account: account) }

  before { sign_in_as(user) }

  describe "GET /feedbacks" do
    it "returns 200" do
      get feedbacks_path
      expect(response).to have_http_status(:ok)
    end

    it "shows feedbacks" do
      create(:feedback, account: account, source: source, content: "Great product!", received_at: 1.day.ago)
      get feedbacks_path
      expect(response.body).to include("Great product!")
    end

    it "filters by sentiment" do
      create(:feedback, :processed, account: account, source: source, sentiment: :positive, received_at: 1.day.ago)
      create(:feedback, :processed, account: account, source: source, sentiment: :negative, received_at: 1.day.ago)
      get feedbacks_path(sentiment: "positive")
      expect(response).to have_http_status(:ok)
    end

    it "filters by search" do
      create(:feedback, account: account, source: source, content: "Payment is broken", received_at: 1.day.ago)
      get feedbacks_path(search: "payment")
      expect(response.body).to include("Payment is broken")
    end
  end

  describe "GET /feedbacks/:id" do
    it "shows a feedback" do
      feedback = create(:feedback, account: account, source: source)
      get feedback_path(feedback)
      expect(response).to have_http_status(:ok)
    end
  end
end
