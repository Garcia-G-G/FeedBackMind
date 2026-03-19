require "rails_helper"

RSpec.describe "Api::V1::Feedbacks", type: :request do
  let(:account) { create(:account) }
  let(:source) { create(:source, account: account) }
  let!(:feedbacks) do
    create_list(:feedback, 5, :processed, account: account, source: source)
  end

  describe "GET /api/v1/feedbacks" do
    it "returns paginated feedbacks" do
      get "/api/v1/feedbacks", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(json_response["feedbacks"].length).to eq(5)
      expect(json_response["meta"]["total_count"]).to eq(5)
    end

    it "filters by sentiment" do
      create(:feedback, :positive, account: account, source: source, processed_at: Time.current)

      get "/api/v1/feedbacks?sentiment=positive", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      json_response["feedbacks"].each do |f|
        expect(f["sentiment"]).to eq("positive")
      end
    end

    it "filters by topic" do
      create(:feedback, account: account, source: source, topics: ["billing"], processed_at: Time.current)

      get "/api/v1/feedbacks?topic=billing", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(json_response["feedbacks"]).to be_present
    end
  end

  describe "GET /api/v1/feedbacks/:id" do
    it "returns detailed feedback" do
      get "/api/v1/feedbacks/#{feedbacks.first.id}", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(json_response["feedback"]["metadata"]).to be_present
    end
  end
end
