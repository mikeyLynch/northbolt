require "rails_helper"

RSpec.describe Tenant, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to have_many(:access_grants).dependent(:destroy) }
    it { is_expected.to have_many(:locks).through(:access_grants) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }

    it "allows blank email and phone" do
      tenant = build(:tenant, email: "", phone: "")
      expect(tenant).to be_valid
    end

    it "enforces email uniqueness within a business when present" do
      business = create(:business)
      create(:tenant, business: business, email: "same@example.com")
      duplicate = build(:tenant, business: business, email: "same@example.com")
      expect(duplicate).not_to be_valid
    end

    it "allows the same email across different businesses" do
      create(:tenant, email: "same@example.com")
      other = build(:tenant, email: "same@example.com")
      expect(other).to be_valid
    end

    it "enforces phone uniqueness within a business when present" do
      business = create(:business)
      create(:tenant, business: business, phone: "07700900001")
      duplicate = build(:tenant, business: business, phone: "07700900001")
      expect(duplicate).not_to be_valid
    end

    it "allows blank phones to coexist within the same business" do
      business = create(:business)
      create(:tenant, business: business, phone: "")
      other = build(:tenant, business: business, phone: "")
      expect(other).to be_valid
    end
  end

  describe "#full_name" do
    it "returns first and last name joined" do
      tenant = build(:tenant, first_name: "Jane", last_name: "Smith")
      expect(tenant.full_name).to eq("Jane Smith")
    end
  end
end
