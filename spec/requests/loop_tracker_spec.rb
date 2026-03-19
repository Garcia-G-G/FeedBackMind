require "rails_helper"

RSpec.describe "Loop Tracker", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in_as(user) }

  describe "GET /loop_tracker" do
    it "returns 200" do
      get loop_tracker_path
      expect(response).to have_http_status(:ok)
    end
  end
end
