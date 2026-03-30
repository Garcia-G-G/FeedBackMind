require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:account) { create(:account, :growth) }
  let(:owner) { create(:user, account: account, role: :owner) }

  before { sign_in_as(owner) }

  describe "GET /invitations" do
    it "returns 200 for owners" do
      get invitations_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects members" do
      member = create(:user, :member, account: account)
      sign_in_as(member)
      get invitations_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /invitations" do
    it "creates an invitation" do
      expect {
        post invitations_path, params: { invitation: { email: "newbie@test.com", role: "member" } }
      }.to change(Invitation, :count).by(1)
      expect(response).to redirect_to(invitations_path)
    end

    it "rejects existing team members" do
      post invitations_path, params: { invitation: { email: owner.email, role: "member" } }
      expect(response).to redirect_to(invitations_path)
      expect(flash[:alert]).to include("already")
    end
  end

  describe "Invitation acceptance" do
    let(:invitation) { create(:invitation, account: account, invited_by: owner) }

    it "shows the acceptance form" do
      sign_out owner
      get accept_invitation_path(token: invitation.token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(account.name)
    end

    it "shows the acceptance form for valid token" do
      sign_out owner
      get accept_invitation_path(token: invitation.token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Join")
    end
  end
end
