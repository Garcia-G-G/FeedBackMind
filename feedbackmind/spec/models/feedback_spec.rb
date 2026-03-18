require "rails_helper"

RSpec.describe Feedback, type: :model do
  describe "validations" do
    it { should validate_presence_of(:content) }
  end

  describe "associations" do
    it { should belong_to(:account) }
    it { should belong_to(:source) }
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:source) { create(:source, account: account) }

    before do
      ActsAsTenant.current_tenant = account
    end

    it ".unprocessed returns feedbacks without processed_at" do
      processed = create(:feedback, :processed, account: account, source: source)
      unprocessed = create(:feedback, :unprocessed, account: account, source: source)

      expect(Feedback.unprocessed).to include(unprocessed)
      expect(Feedback.unprocessed).not_to include(processed)
    end

    it ".by_topic finds feedbacks with matching topic" do
      fb = create(:feedback, account: account, source: source, topics: ["billing", "pricing"])
      other = create(:feedback, account: account, source: source, topics: ["onboarding"])

      expect(Feedback.by_topic("billing")).to include(fb)
      expect(Feedback.by_topic("billing")).not_to include(other)
    end
  end
end
