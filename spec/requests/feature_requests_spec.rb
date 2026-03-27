require "rails_helper"

RSpec.describe "Feature Requests", type: :request do
  let(:account) { create(:account, :growth) }
  let(:user) { create(:user, account: account) }

  before { sign_in_as(user) }

  describe "GET /feature_requests" do
    it "returns 200" do
      get feature_requests_path
      expect(response).to have_http_status(:ok)
    end

    it "lists feature requests" do
      ActsAsTenant.current_tenant = account
      fr = create(:feature_request, :published, account: account)
      get feature_requests_path
      expect(response.body).to include(fr.title)
    end
  end

  describe "POST /feature_requests" do
    it "creates a feature request" do
      expect {
        post feature_requests_path, params: {
          feature_request: { title: "Add dark mode", description: "Please", author_email: user.email }
        }
      }.to change(FeatureRequest, :count).by(1)
      expect(response).to redirect_to(feature_request_path(FeatureRequest.last))
    end
  end

  describe "DELETE /feature_requests/:id" do
    it "deletes the request" do
      ActsAsTenant.current_tenant = account
      fr = create(:feature_request, account: account)
      expect {
        delete feature_request_path(fr)
      }.to change(FeatureRequest, :count).by(-1)
    end
  end
end
