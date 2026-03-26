require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let(:account) { create(:account) }

  describe "unonboarded user" do
    let(:user) { create(:user, account: account, onboarding_completed_at: nil, onboarding_step: 0) }

    before { sign_in user }

    it "redirects to onboarding from dashboard" do
      get "/dashboard"
      expect(response).to redirect_to(onboarding_path)
    end

    it "shows step 1 on first visit" do
      get "/onboarding"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("plan-selector")
    end

    it "selects free plan on step 1" do
      patch "/onboarding", params: { account: { plan: "starter" } }
      expect(response).to redirect_to(onboarding_path)
      expect(account.reload.plan).to eq("starter")
      expect(user.reload.onboarding_step).to eq(2)
    end

    it "updates account info on step 2" do
      user.update!(onboarding_step: 2)
      patch "/onboarding", params: { account: { name: "New Team", subdomain: "new-team" } }
      expect(response).to redirect_to(onboarding_path)
      expect(account.reload.name).to eq("New Team")
      expect(user.reload.onboarding_step).to eq(3)
    end

    it "completes onboarding on step 3" do
      user.update!(onboarding_step: 3)
      patch "/onboarding"
      expect(response).to redirect_to(dashboard_path)
      expect(user.reload.onboarding_completed_at).to be_present
    end

    it "handles back navigation" do
      user.update!(onboarding_step: 2)
      patch "/onboarding", params: { back: "true" }
      expect(response).to redirect_to(onboarding_path)
      expect(user.reload.onboarding_step).to eq(1)
    end
  end

  describe "onboarded user" do
    let(:user) { create(:user, account: account, onboarding_completed_at: Time.current, onboarding_step: 3) }

    before { sign_in user }

    it "does not redirect to onboarding" do
      get "/dashboard"
      expect(response).to have_http_status(:ok)
    end

    it "redirects away from onboarding" do
      get "/onboarding"
      expect(response).to redirect_to(dashboard_path)
    end
  end
end
