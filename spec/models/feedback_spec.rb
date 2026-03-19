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

    before { ActsAsTenant.current_tenant = account }

    it ".unprocessed returns unprocessed feedbacks" do
      processed = create(:feedback, :processed, account: account, source: source)
      unprocessed = create(:feedback, account: account, source: source, processed_at: nil)
      expect(Feedback.unprocessed).to include(unprocessed)
      expect(Feedback.unprocessed).not_to include(processed)
    end

    it ".by_topic finds by topic" do
      fb = create(:feedback, account: account, source: source, topics: ["billing", "pricing"])
      other = create(:feedback, account: account, source: source, topics: ["onboarding"])
      expect(Feedback.by_topic("billing")).to include(fb)
      expect(Feedback.by_topic("billing")).not_to include(other)
    end

    it ".by_sentiment filters sentiment" do
      pos = create(:feedback, account: account, source: source, sentiment: :positive)
      neg = create(:feedback, account: account, source: source, sentiment: :negative)
      expect(Feedback.by_sentiment("positive")).to include(pos)
      expect(Feedback.by_sentiment("positive")).not_to include(neg)
    end
  end
end
