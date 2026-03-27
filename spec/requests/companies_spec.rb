require "rails_helper"

RSpec.describe "Companies", type: :request do
  let(:account) { create(:account, :growth) }
  let(:user) { create(:user, account: account) }

  before { sign_in_as(user) }

  describe "GET /companies" do
    it "returns 200" do
      get companies_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /companies/:id" do
    it "shows a company" do
      ActsAsTenant.current_tenant = account
      company = create(:company, account: account)
      get company_path(company)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(company.name)
    end
  end

  describe "POST /companies/auto_match" do
    it "redirects with notice" do
      post auto_match_companies_path
      expect(response).to redirect_to(companies_path)
    end
  end
end
