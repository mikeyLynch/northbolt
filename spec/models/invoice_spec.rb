require "rails_helper"

RSpec.describe Invoice, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to have_many(:line_items).dependent(:destroy) }
    it { is_expected.to have_many(:refunds).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:invoice) }
    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_uniqueness_of(:number) }
  end

  describe ".next_number" do
    it "generates a sequential number for the current year" do
      expect(Invoice.next_number).to match(/\ANB-\d{4}-\d{3}\z/)
    end

    it "increments with each invoice created" do
      business = create(:business)
      Invoice.create_hardware!(business: business, lock_count: 1, installment: :deposit)
      second = Invoice.next_number
      expect(second).to end_with("-002")
    end
  end

  describe ".create_hardware!" do
    let(:business) { create(:business) }

    it "creates an invoice with the correct subtotal for a deposit" do
      invoice = Invoice.create_hardware!(business: business, lock_count: 10, installment: :deposit)
      expect(invoice.subtotal_pence).to eq(10 * Invoice::HARDWARE_UNIT_PRICE_PENCE / 2)
    end

    it "creates an invoice with the full amount for a full installment" do
      invoice = Invoice.create_hardware!(business: business, lock_count: 10, installment: :full)
      expect(invoice.subtotal_pence).to eq(10 * Invoice::HARDWARE_UNIT_PRICE_PENCE)
    end

    it "creates line items" do
      invoice = Invoice.create_hardware!(business: business, lock_count: 5, installment: :deposit)
      expect(invoice.line_items.count).to eq(1)
    end

    it "starts in draft status" do
      invoice = Invoice.create_hardware!(business: business, lock_count: 5, installment: :deposit)
      expect(invoice).to be_draft
    end

    it "applies a percentage discount" do
      invoice = Invoice.create_hardware!(business: business, lock_count: 10, installment: :deposit,
                                         discount_type: "percentage", discount_value: 10)
      subtotal = 10 * Invoice::HARDWARE_UNIT_PRICE_PENCE / 2
      expect(invoice.discount_amount_pence).to eq((subtotal * 0.10).round)
    end

    it "applies a fixed discount" do
      invoice = Invoice.create_hardware!(business: business, lock_count: 10, installment: :deposit,
                                         discount_type: "fixed", discount_value: 5000)
      expect(invoice.discount_amount_pence).to eq(5000)
    end

    it "calculates VAT on the post-discount net" do
      invoice = Invoice.create_hardware!(business: business, lock_count: 10, installment: :deposit,
                                         discount_type: "fixed", discount_value: 5000)
      net = invoice.subtotal_pence - invoice.discount_amount_pence
      expect(invoice.vat_pence).to eq((net * 0.20).round)
    end

    it "sets total to net + VAT" do
      invoice = Invoice.create_hardware!(business: business, lock_count: 10, installment: :deposit)
      expect(invoice.total_pence).to eq(invoice.net_pence + invoice.vat_pence)
    end
  end

  describe ".create_service!" do
    let(:business)  { create(:business) }
    let(:location)  { create(:location, business: business) }

    before { create_list(:lock, 5, location: location) }

    it "creates an invoice for the number of locks on the business" do
      invoice = Invoice.create_service!(business: business)
      expect(invoice.subtotal_pence).to eq(5 * Invoice::SERVICE_ANNUAL_PENCE_PER_LOCK)
    end

    it "sets the service period" do
      invoice = Invoice.create_service!(business: business)
      expect(invoice.service_period_start).to eq(Date.current)
      expect(invoice.service_period_end).to eq(Date.current + 1.year - 1.day)
    end
  end

  describe ".create_delivery_and_service!" do
    let(:business) { create(:business) }

    it "creates an invoice with two line items" do
      invoice = Invoice.create_delivery_and_service!(business: business, lock_count: 10)
      expect(invoice.line_items.count).to eq(2)
    end

    it "combines hardware delivery and service fee in the subtotal" do
      invoice = Invoice.create_delivery_and_service!(business: business, lock_count: 10)
      hardware = (Invoice::HARDWARE_UNIT_PRICE_PENCE * 10 / 2.0).round
      service  = Invoice::SERVICE_ANNUAL_PENCE_PER_LOCK * 10
      expect(invoice.subtotal_pence).to eq(hardware + service)
    end

    it "sets the service period" do
      invoice = Invoice.create_delivery_and_service!(business: business, lock_count: 10)
      expect(invoice.service_period_start).to eq(Date.current)
      expect(invoice.service_period_end).to eq(Date.current + 1.year - 1.day)
    end
  end

  describe "#net_pence" do
    it "returns subtotal minus discount" do
      invoice = build(:invoice, subtotal_pence: 100_000, discount_amount_pence: 10_000)
      expect(invoice.net_pence).to eq(90_000)
    end
  end

  describe "#refunded_pence" do
    let(:invoice) { create(:invoice, :paid) }

    it "returns the sum of all refunds" do
      create(:refund, invoice: invoice, amount_pence: 3_000)
      create(:refund, invoice: invoice, amount_pence: 2_000)
      expect(invoice.refunded_pence).to eq(5_000)
    end

    it "returns 0 with no refunds" do
      expect(invoice.refunded_pence).to eq(0)
    end
  end

  describe "formatted helpers" do
    let(:invoice) { build(:invoice, total_pence: 179_400, subtotal_pence: 149_500, vat_pence: 29_900, discount_amount_pence: 0) }

    it "#formatted_total returns £ formatted string" do
      expect(invoice.formatted_total).to eq("£1794.00")
    end

    it "#formatted_subtotal" do
      expect(invoice.formatted_subtotal).to eq("£1495.00")
    end

    it "#formatted_vat" do
      expect(invoice.formatted_vat).to eq("£299.00")
    end
  end
end
