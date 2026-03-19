require "rails_helper"

RSpec.describe Source, type: :model do
  describe "validations" do
    it { should validate_presence_of(:source_type) }
  end

  describe "associations" do
    it { should belong_to(:account) }
    it { should have_many(:feedbacks).dependent(:destroy) }
  end

  describe "scopes" do
    let(:account) { create(:account, :scale) }

    before { ActsAsTenant.current_tenant = account }

    it ".active returns active sources" do
      active = create(:source, account: account, active: true)
      inactive = create(:source, account: account, active: false, source_type: :gmail)
      expect(Source.active).to include(active)
      expect(Source.active).not_to include(inactive)
    end
  end
end
