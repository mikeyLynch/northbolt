# Invoices are created manually by Northbolt staff via rake tasks and sent to business owners by email.
# Businesses never create invoices themselves — they only view and download them on the billing dashboard.
#
# There are two categories of invoice:
#   hardware — a one-time charge for physical locks (£299/lock). Split into two installments:
#              deposit (50% upfront) and delivery (50% on hardware dispatch). Use installment: :full
#              if charging in a single payment.
#   service  — an annual fee charged per lock (£4/lock/month, billed yearly). Raised at installation
#              and renewed on the same date each year. service_period_start/end record the coverage window.
#
# Lifecycle: draft → outstanding (sent to customer) → paid
#   draft:       created but not yet emailed. Safe to discard if something is wrong.
#   outstanding: emailed via SendInvoiceJob. issued_at and due_at are stamped at send time.
#   paid:        marked paid manually via rake task when BACS payment is confirmed. paid_at is stamped.
#
# Money fields:
#   All monetary values are stored in pence (integers) to avoid floating point issues.
#   subtotal_pence      — gross amount before any discount
#   discount_type       — "fixed" (pence) or "percentage" (applied to subtotal)
#   discount_value      — the raw discount input (pence amount or percentage number)
#   discount_amount_pence — the computed discount in pence, stored at creation time
#   vat_rate            — decimal rate stamped at creation (e.g. 0.2 for 20%). Stored so historical
#                         invoices are unaffected if the rate changes in future.
#   vat_pence           — VAT applied to (subtotal - discount), rounded to nearest penny
#   total_pence         — net + VAT (what the customer actually pays)
#
# Refunds are separate records linked to an invoice. They do not change the invoice status or total —
# they are tracked alongside the invoice and shown on the billing dashboard.
class Invoice < ApplicationRecord
  COMPANY_NAME    = "Northbolt Ltd".freeze
  COMPANY_ADDRESS = "123 Placeholder Street, Edinburgh, EH1 1AB".freeze
  COMPANY_NUMBER  = "SC000000".freeze
  COMPANY_VAT     = "GB000000000".freeze
  COMPANY_EMAIL   = "hello@northbolt.co.uk".freeze
  COMPANY_BACS    = "Sort code: 00-00-00 · Account: 00000000".freeze

  HARDWARE_UNIT_PRICE_PENCE = 29_900
  SERVICE_ANNUAL_PENCE_PER_LOCK = 4_800  # £48/year = £4/month

  belongs_to :business
  has_many   :line_items, class_name: "InvoiceLineItem", dependent: :destroy
  has_many   :refunds,    dependent: :destroy

  enum :category,    { hardware: "hardware", service: "service" }
  enum :installment, { deposit: "deposit", delivery: "delivery", full: "full" }, prefix: true
  enum :status,      { draft: "draft", outstanding: "outstanding", paid: "paid" }

  validates :number,         presence: true, uniqueness: true
  validates :category,       presence: true
  validates :status,         presence: true
  validates :subtotal_pence, presence: true
  validates :vat_rate,       presence: true
  validates :vat_pence,      presence: true
  validates :total_pence,    presence: true

  scope :recent, -> { order(created_at: :desc) }

  def self.next_number
    year  = Date.current.year
    count = where("number LIKE ?", "NB-#{year}-%").count + 1
    "NB-#{year}-#{count.to_s.rjust(3, '0')}"
  end

  def self.create_hardware!(business:, lock_count:, installment:, discount_type: nil, discount_value: nil)
    gross      = HARDWARE_UNIT_PRICE_PENCE * lock_count
    half       = (gross / 2.0).round
    base_pence = installment.to_s == "full" ? gross : half

    build_invoice(
      business:       business,
      category:       :hardware,
      installment:    installment,
      subtotal_pence: base_pence,
      discount_type:  discount_type,
      discount_value: discount_value,
      line_items:     [
        { description: "Northbolt Smart Lock × #{lock_count}", quantity: lock_count, unit_price_pence: HARDWARE_UNIT_PRICE_PENCE }
      ]
    )
  end

  def self.create_delivery_and_service!(business:, lock_count:, discount_type: nil, discount_value: nil)
    hardware_pence = (HARDWARE_UNIT_PRICE_PENCE * lock_count / 2.0).round
    service_pence  = SERVICE_ANNUAL_PENCE_PER_LOCK * lock_count
    subtotal_pence = hardware_pence + service_pence
    period_start   = Date.current
    period_end     = period_start + 1.year - 1.day

    build_invoice(
      business:             business,
      category:             :hardware,
      installment:          :delivery,
      subtotal_pence:       subtotal_pence,
      discount_type:        discount_type,
      discount_value:       discount_value,
      service_period_start: period_start,
      service_period_end:   period_end,
      line_items:           [
        { description: "Northbolt Smart Lock × #{lock_count} (delivery balance)", quantity: lock_count, unit_price_pence: (HARDWARE_UNIT_PRICE_PENCE / 2.0).round },
        { description: "Annual service fee × #{lock_count} locks",                quantity: lock_count, unit_price_pence: SERVICE_ANNUAL_PENCE_PER_LOCK }
      ]
    )
  end

  def self.create_service!(business:, discount_type: nil, discount_value: nil)
    lock_count     = business.locks.count
    subtotal_pence = SERVICE_ANNUAL_PENCE_PER_LOCK * lock_count
    period_start   = Date.current
    period_end     = period_start + 1.year - 1.day

    build_invoice(
      business:             business,
      category:             :service,
      installment:          :full,
      subtotal_pence:       subtotal_pence,
      discount_type:        discount_type,
      discount_value:       discount_value,
      service_period_start: period_start,
      service_period_end:   period_end,
      line_items:           [
        { description: "Annual service fee × #{lock_count} locks", quantity: lock_count, unit_price_pence: SERVICE_ANNUAL_PENCE_PER_LOCK }
      ]
    )
  end

  def net_pence
    subtotal_pence - discount_amount_pence
  end

  def formatted_total
    format("£%.2f", total_pence / 100.0)
  end

  def formatted_subtotal
    format("£%.2f", subtotal_pence / 100.0)
  end

  def formatted_discount
    format("£%.2f", discount_amount_pence / 100.0)
  end

  def formatted_vat
    format("£%.2f", vat_pence / 100.0)
  end

  def refunded_pence
    refunds.sum(:amount_pence)
  end

  private

  def self.build_invoice(business:, category:, installment:, subtotal_pence:, discount_type:, discount_value:, line_items:, service_period_start: nil, service_period_end: nil)
    discount_amount = calculate_discount(subtotal_pence, discount_type, discount_value)
    net             = subtotal_pence - discount_amount
    vat             = (net * 0.20).round
    total           = net + vat

    invoice = create!(
      business:             business,
      number:               next_number,
      category:             category,
      installment:          installment,
      status:               :draft,
      subtotal_pence:       subtotal_pence,
      discount_type:        discount_type,
      discount_value:       discount_value,
      discount_amount_pence: discount_amount,
      vat_rate:             0.20,
      vat_pence:            vat,
      total_pence:          total,
      issued_at:            Date.current,
      due_at:               Date.current + 30.days,
      service_period_start: service_period_start,
      service_period_end:   service_period_end
    )

    line_items.each do |item|
      invoice.line_items.create!(
        description:      item[:description],
        quantity:         item[:quantity],
        unit_price_pence: item[:unit_price_pence],
        total_pence:      (item[:unit_price_pence] * item[:quantity]).round
      )
    end

    invoice
  end

  def self.calculate_discount(subtotal_pence, discount_type, discount_value)
    return 0 unless discount_type.present? && discount_value.present?

    case discount_type.to_s
    when "fixed"      then discount_value.to_i
    when "percentage" then (subtotal_pence * discount_value.to_f / 100).round
    else 0
    end
  end
end
