require "rails_helper"

RSpec.describe InvoiceLineItem, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:invoice) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_presence_of(:unit_price_pence) }
    it { is_expected.to validate_presence_of(:total_pence) }
  end

  describe "#formatted_unit_price" do
    it "formats pence as pounds" do
      item = build(:invoice_line_item, unit_price_pence: 29_900)
      expect(item.formatted_unit_price).to eq("£299.00")
    end
  end

  describe "#formatted_total" do
    it "formats pence as pounds" do
      item = build(:invoice_line_item, total_pence: 299_000)
      expect(item.formatted_total).to eq("£2990.00")
    end
  end
end
