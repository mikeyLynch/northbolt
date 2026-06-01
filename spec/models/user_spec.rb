require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business) }
  end

  describe "role enum" do
    it "defaults to owner" do
      expect(create(:user).role).to eq("owner")
    end

    it "supports owner, high, medium, low" do
      %w[owner high medium low].each do |role|
        expect(build(:user, role: role).role).to eq(role)
      end
    end

    it "provides predicate methods" do
      expect(build(:user, role: "owner")).to be_owner
      expect(build(:user, role: "high")).to be_high
      expect(build(:user, role: "medium")).to be_medium
      expect(build(:user, role: "low")).to be_low
    end
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
  end
end
