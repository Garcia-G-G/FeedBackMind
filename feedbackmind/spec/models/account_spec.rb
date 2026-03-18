require "rails_helper"

RSpec.describe Account, type: :model do
  describe "validations" do
    subject { build(:account) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:subdomain) }
    it { should validate_uniqueness_of(:subdomain) }
    it { should validate_presence_of(:plan) }
  end

  describe "associations" do
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:sources).dependent(:destroy) }
    it { should have_many(:feedbacks).dependent(:destroy) }
    it { should have_many(:weekly_syntheses).dependent(:destroy) }
    it { should have_many(:chat_messages).dependent(:destroy) }
  end

  describe "#feedback_limit_reached?" do
    it "returns true when starter plan hits 500" do
      account = build(:account, plan: :starter, feedback_count_this_month: 500)
      expect(account.feedback_limit_reached?).to be true
    end

    it "returns false for scale plan regardless of count" do
      account = build(:account, :scale, feedback_count_this_month: 999_999)
      expect(account.feedback_limit_reached?).to be false
    end

    it "returns false when under limit" do
      account = build(:account, plan: :starter, feedback_count_this_month: 100)
      expect(account.feedback_limit_reached?).to be false
    end
  end

  describe "#plan_limits" do
    it "returns correct limits for growth plan" do
      account = build(:account, :growth)
      expect(account.plan_limits[:feedbacks_per_month]).to eq(2_000)
      expect(account.plan_limits[:chat_enabled]).to be true
    end
  end
end
