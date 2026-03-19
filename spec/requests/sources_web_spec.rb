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
      post sources_path, params: { source: { source_type: "slack" } }
      expect(response).to redirect_to(Source.last)
      expect(account.sources.where(source_type: :slack).count).to eq(1)
    end
  end

  describe "DELETE /sources/:id" do
    it "destroys a source" do
      source = create(:source, account: account)
      delete source_path(source)
      expect(response).to redirect_to(sources_url)
      expect(Source.find_by(id: source.id)).to be_nil
    end
  end
end
