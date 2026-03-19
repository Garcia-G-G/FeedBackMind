require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:role) }
  end

  describe "associations" do
    it { should belong_to(:account) }
    it { should have_many(:chat_messages).dependent(:destroy) }
  end

  describe "#owner?" do
    it "returns true for owner role" do
      expect(build(:user, role: :owner).owner?).to be true
    end

    it "returns false for member role" do
      expect(build(:user, :member, role: :member).owner?).to be false
    end
  end

  describe "#display_name" do
    it "returns name when present" do
      expect(build(:user, name: "Jane").display_name).to eq("Jane")
    end

    it "returns email prefix when name is blank" do
      expect(build(:user, name: nil, email: "jane@example.com").display_name).to eq("jane")
    end
  end
end
