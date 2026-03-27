require "rails_helper"

RSpec.describe Companies::AutoMatcher do
  let(:account) { create(:account) }
  let(:source) { create(:source, account: account) }

  before { ActsAsTenant.current_tenant = account }

  describe "#match" do
    it "creates a company from email domain" do
      feedback = create(:feedback, account: account, source: source, author_email: "john@acmecorp.com")
      matcher = described_class.new(account)

      expect { matcher.match(feedback) }.to change(Company, :count).by(1)
      expect(feedback.reload.company.domain).to eq("acmecorp.com")
      expect(feedback.company.name).to eq("Acmecorp")
    end

    it "skips free email domains" do
      feedback = create(:feedback, account: account, source: source, author_email: "john@gmail.com")
      matcher = described_class.new(account)

      expect { matcher.match(feedback) }.not_to change(Company, :count)
    end

    it "reuses existing company" do
      create(:company, account: account, domain: "acme.com", name: "Acme")
      feedback = create(:feedback, account: account, source: source, author_email: "jane@acme.com")
      matcher = described_class.new(account)

      expect { matcher.match(feedback) }.not_to change(Company, :count)
      expect(feedback.reload.company.name).to eq("Acme")
    end
  end
end
