require "rails_helper"

RSpec.describe "Sources (Web)", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in_as(user) }

  describe "GET /sources" do
    it "returns 200" do
      get sources_path
      expect(response).to have_http_status(:ok)
    end

    it "lists sources" do
      create(:source, account: account, source_type: :intercom)
      get sources_path
      expect(response.body).to include("Intercom")
    end
  end

  describe "GET /sources/new" do
    it "returns 200" do
      get new_source_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /sources" do
    it "creates a source" do
      expect {
        post sources_path, params: { source: { source_type: "slack" } }
      }.to change(Source, :count).by(1)
    end
  end

  describe "DELETE /sources/:id" do
    it "destroys a source" do
      source = create(:source, account: account)
      expect {
        delete source_path(source)
      }.to change(Source, :count).by(-1)
      expect(response).to redirect_to(sources_url)
    end
  end
end
