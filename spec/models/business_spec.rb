require 'rails_helper'

RSpec.describe Business, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:locations).dependent(:destroy) }
    it { is_expected.to have_many(:users).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "#vat_registered?" do
    it "returns true when vat_number is present" do
      expect(build(:business, vat_number: "GB123456789")).to be_vat_registered
    end

    it "returns false when vat_number is blank" do
      expect(build(:business, vat_number: nil)).not_to be_vat_registered
    end
  end

  describe "#role_can?" do
    let(:business) { create(:business) }

    it "returns true when the role has the permission" do
      expect(business.role_can?("high", "manage_team")).to be true
    end

    it "returns false when the role does not have the permission" do
      expect(business.role_can?("low", "manage_team")).to be false
    end

    it "returns false for an unknown role" do
      expect(business.role_can?("unknown", "manage_team")).to be false
    end

    it "returns false for an unknown permission" do
      expect(business.role_can?("high", "fly_a_spaceship")).to be false
    end

    it "reflects changes to the permission matrix" do
      business.update!(permission_matrix: business.permission_matrix.merge("low" => ["manage_team"]))
      expect(business.role_can?("low", "manage_team")).to be true
    end
  end
end
