require "rails_helper"

RSpec.describe "Changelog Entries", type: :request do
  let(:account) { create(:account, :growth) }
  let(:user) { create(:user, account: account) }

  before { sign_in_as(user) }

  describe "GET /changelog" do
    it "returns 200" do
      get changelog_entries_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /changelog" do
    it "creates an entry" do
      expect {
        post changelog_entries_path, params: {
          changelog_entry: { title: "New Feature", body: "We shipped it!", category: "new_feature" }
        }
      }.to change(ChangelogEntry, :count).by(1)
    end
  end

  describe "GET /changelog/:id" do
    it "shows the entry" do
      ActsAsTenant.current_tenant = account
      entry = create(:changelog_entry, account: account)
      get changelog_entry_path(entry)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(entry.title)
    end
  end
end
