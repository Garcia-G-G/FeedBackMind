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

  describe "#plan_limits" do
    it "returns correct limits for each plan" do
      expect(build(:account, plan: :starter).plan_limits[:feedbacks_per_month]).to eq(500)
      expect(build(:account, :growth).plan_limits[:feedbacks_per_month]).to eq(2_000)
      expect(build(:account, :scale).plan_limits[:feedbacks_per_month]).to eq(Float::INFINITY)
    end
  end

  describe "#feedback_limit_reached?" do
    it "returns true when at limit" do
      expect(build(:account, plan: :starter, feedback_count_this_month: 500).feedback_limit_reached?).to be true
    end

    it "returns false for scale plan" do
      expect(build(:account, :scale, feedback_count_this_month: 999_999).feedback_limit_reached?).to be false
    end

    it "returns false when under limit" do
      expect(build(:account, plan: :starter, feedback_count_this_month: 100).feedback_limit_reached?).to be false
    end
  end

  describe "#chat_enabled?" do
    it "is false for starter, true for growth/scale" do
      expect(build(:account, plan: :starter).chat_enabled?).to be false
      expect(build(:account, :growth).chat_enabled?).to be true
      expect(build(:account, :scale).chat_enabled?).to be true
    end
  end

  describe "api_token" do
    it "generates on create" do
      account = create(:account)
      expect(account.api_token).to start_with("fm_")
    end

    it "regenerates" do
      account = create(:account)
      old = account.api_token
      account.regenerate_api_token!
      expect(account.api_token).not_to eq(old)
    end
  end
end
