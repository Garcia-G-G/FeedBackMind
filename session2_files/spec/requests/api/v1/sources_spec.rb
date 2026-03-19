require "rails_helper"

RSpec.describe "Api::V1::Sources", type: :request do
  let(:account) { create(:account) }
  let!(:source) { create(:source, account: account, source_type: :intercom, active: true) }

  describe "GET /api/v1/sources" do
    it "returns all sources for the account" do
      get "/api/v1/sources", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(json_response["sources"].length).to eq(1)
      expect(json_response["sources"][0]["source_type"]).to eq("intercom")
    end
  end

  describe "POST /api/v1/sources" do
    it "creates a new source" do
      post "/api/v1/sources",
           params: { source: { source_type: "slack", config: { "signing_secret" => "test" } } }.to_json,
           headers: api_headers(account)

      expect(response).to have_http_status(:created)
      expect(json_response["source"]["source_type"]).to eq("slack")
    end
  end

  describe "POST /api/v1/sources/:id/activate" do
    let(:inactive_source) { create(:source, :inactive, account: account) }

    it "activates a source" do
      post "/api/v1/sources/#{inactive_source.id}/activate", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(inactive_source.reload.active).to be true
    end
  end

  describe "DELETE /api/v1/sources/:id" do
    it "deletes a source" do
      delete "/api/v1/sources/#{source.id}", headers: api_headers(account)
      expect(response).to have_http_status(:no_content)
      expect(Source.find_by(id: source.id)).to be_nil
    end
  end
end
