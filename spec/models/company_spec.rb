require "rails_helper"

RSpec.describe Company, type: :model do
  let(:account) { create(:account) }

  before { ActsAsTenant.current_tenant = account }

  it "validates name presence" do
    company = build(:company, account: account, name: nil)
    expect(company).not_to be_valid
  end

  it "enforces unique domain per account" do
    create(:company, account: account, domain: "acme.com")
    dup = build(:company, account: account, domain: "acme.com")
    expect(dup).not_to be_valid
  end
end
