require "rails_helper"

RSpec.describe Refund, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:invoice) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:reason) }
    it { is_expected.to validate_presence_of(:issued_at) }
    it { is_expected.to validate_numericality_of(:amount_pence).is_greater_than(0) }
  end

  describe "#formatted_amount" do
    it "formats pence as pounds" do
      expect(build(:refund, amount_pence: 5_000).formatted_amount).to eq("£50.00")
    end
  end
end
