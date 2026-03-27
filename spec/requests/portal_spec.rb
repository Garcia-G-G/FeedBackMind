require "rails_helper"

RSpec.describe "Portal", type: :request do
  let(:account) { create(:account, :growth) }

  describe "GET /portal/:subdomain" do
    it "returns 200 for valid account" do
      get portal_path(portal_subdomain: account.subdomain)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for invalid subdomain" do
      get portal_path(portal_subdomain: "nonexistent-xyz")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /portal/:subdomain/roadmap" do
    it "returns 200" do
      get portal_roadmap_path(portal_subdomain: account.subdomain)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /portal/:subdomain/changelog" do
    it "returns 200" do
      get portal_changelog_path(portal_subdomain: account.subdomain)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /portal/:subdomain (create_request)" do
    it "creates a feature request" do
      expect {
        post portal_create_request_path(portal_subdomain: account.subdomain), params: {
          feature_request: {
            title: "Add dark mode",
            description: "Please add dark mode",
            author_email: "user@example.com",
            author_name: "Test User"
          }
        }
      }.to change(FeatureRequest, :count).by(1)
      expect(response).to redirect_to(portal_path(portal_subdomain: account.subdomain))
    end
  end

  context "with starter plan (portal disabled)" do
    let(:starter_account) { create(:account) }

    it "returns 403" do
      get portal_path(portal_subdomain: starter_account.subdomain)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
